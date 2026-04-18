import Foundation
@preconcurrency import AVFoundation
import Combine
import FirebaseAILogic
import os.log

private nonisolated let liveLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Alba", category: "GeminiLiveService")

/// Real-time voice bridge to Gemini via Firebase AI Logic SDK.
///
/// Audio pipeline:
/// - Mic capture via `AVAudioEngine` input tap, device-native format.
/// - `AVAudioConverter` resamples each buffer down to 16-bit PCM 16 kHz mono.
/// - Chunks are streamed to the model with `LiveSession.sendAudioRealtime(_:)`.
/// - Model returns 16-bit PCM 24 kHz mono chunks which we play via
///   `AVAudioPlayerNode`, after computing their RMS for the orb animation.
@MainActor
final class GeminiLiveService: ObservableObject {
    // MARK: - Published state
    @Published var isConnected: Bool = false
    @Published var isModelSpeaking: Bool = false
    @Published var isUserSpeaking: Bool = false
    @Published var outputAudioLevel: Float = 0
    @Published var inputAudioLevel: Float = 0
    @Published var errorMessage: String?

    // MARK: - Session / engine
    private var session: LiveSession?
    private let audioEngine = AVAudioEngine()
    private let audioPlayerNode = AVAudioPlayerNode()
    private var responseTask: Task<Void, Never>?
    private var isMicTapInstalled = false
    private var isPaused = false

    // Half-duplex guard: when Alba is speaking, stop forwarding the mic to
    // the server. This prevents echo-path feedback (Alba's voice leaking from
    // the speaker into the mic) from being interpreted as end-of-speech,
    // which was the root cause of "dime, dime" / "te escucho" filler.
    // Accessed from the audio thread → nonisolated(unsafe) atomic-ish Bool.
    private nonisolated(unsafe) var suppressMicSend: Bool = false

    // AVAudioConverter is only touched from the realtime audio thread after being
    // set up on the main actor. We expose it as nonisolated(unsafe) so the tap
    // callback can read it without crossing the actor boundary.
    private nonisolated(unsafe) var inputConverter: AVAudioConverter?

    /// Format the model outputs audio in.
    private let playbackFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 24000,
        channels: 1,
        interleaved: true
    )!

    /// Format the model expects for input audio.
    private let targetInputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000,
        channels: 1,
        interleaved: true
    )!

    init() {
        audioEngine.attach(audioPlayerNode)
        audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: playbackFormat)
        // Enable hardware-level echo cancellation / noise suppression so Alba's
        // voice doesn't feed back into the mic while she's speaking.
        try? audioEngine.inputNode.setVoiceProcessingEnabled(true)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - AVAudioSession

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        // `.voiceChat` mode already picks the right processing chain. We DROP
        // `.allowBluetoothA2DP` because A2DP is output-only and forces costly
        // profile switches that can hand us back a zero-sample-rate mic format
        // on iOS 26. HFP remains so headsets with mic still work.
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetoothHFP]
        )
        // Prefer a tight I/O buffer for low-latency real-time conversation.
        try? session.setPreferredIOBufferDuration(0.02) // ~20 ms
        try session.setActive(true, options: [])
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }

        switch type {
        case .began:
            liveLogger.info("📞 Audio session interrupted (incoming call)")
            Task { @MainActor in self.pause() }
        case .ended:
            liveLogger.info("📞 Audio session interruption ended")
        @unknown default:
            break
        }
    }

    // MARK: - Connect

    func connect(systemInstruction: String, voiceName: String) async throws {
        liveLogger.info("🔌 Connecting Gemini Live. model=\(RemoteConfigService.shared.geminiLiveModel) voice=\(voiceName)")

        // 1. Audio session FIRST — must be active before the engine queries formats.
        try configureAudioSession()

        // 2. Prepare & start the engine BEFORE the network call. This gives
        //    AVAudioEngine time to negotiate formats with the active session.
        audioEngine.prepare()
        if !audioEngine.isRunning {
            try audioEngine.start()
        }

        // 3. Now make the network handshake to Gemini.
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let speechConfig = SpeechConfig(voiceName: voiceName)

        let config = LiveGenerationConfig(
            responseModalities: [.audio],
            speech: speechConfig
        )

        let liveModel = ai.liveModel(
            modelName: RemoteConfigService.shared.geminiLiveModel,
            generationConfig: config,
            systemInstruction: ModelContent(role: "system", parts: TextPart(systemInstruction))
        )

        session = try await liveModel.connect()

        isConnected = true
        isPaused = false
        startResponseListener()
        startMicCapture()
        liveLogger.info("✅ Gemini Live session connected")
    }

    // MARK: - Disconnect

    func disconnect() async {
        liveLogger.info("🔌 Disconnecting Gemini Live session")
        responseTask?.cancel()
        responseTask = nil

        if isMicTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isMicTapInstalled = false
        }

        audioPlayerNode.stop()
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        await session?.close()
        session = nil

        isConnected = false
        isModelSpeaking = false
        isUserSpeaking = false
        outputAudioLevel = 0
        inputAudioLevel = 0
        suppressMicSend = false

        deactivateAudioSession()
    }

    // MARK: - Pause / Resume

    func pause() {
        guard !isPaused else { return }
        isPaused = true
        audioPlayerNode.pause()
        if isMicTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isMicTapInstalled = false
        }
        isUserSpeaking = false
        inputAudioLevel = 0
        liveLogger.info("⏸️ Voice session paused")
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        // If the engine was stopped by the system while paused, bring it back.
        if !audioEngine.isRunning {
            do {
                audioEngine.prepare()
                try audioEngine.start()
            } catch {
                liveLogger.error("❌ Failed to restart engine on resume: \(error.localizedDescription)")
                return
            }
        }
        audioPlayerNode.play()
        startMicCapture()
        liveLogger.info("▶️ Voice session resumed")
    }

    /// Stops playback and flushes the buffer queue. Use when we want to cut Alba off early.
    func interrupt() {
        audioPlayerNode.stop()
        audioPlayerNode.reset()
        audioPlayerNode.play()
        isModelSpeaking = false
        outputAudioLevel = 0
        suppressMicSend = false
    }

    // MARK: - Mic Capture

    private func startMicCapture() {
        guard !isMicTapInstalled else { return }

        // If the engine stopped during a pause/resume dance, bring it back up.
        if !audioEngine.isRunning {
            do {
                audioEngine.prepare()
                try audioEngine.start()
            } catch {
                liveLogger.error("❌ Failed to restart audio engine: \(error.localizedDescription)")
                return
            }
        }

        let inputNode = audioEngine.inputNode

        // iOS 26 + .voiceChat: outputFormat(forBus:) sometimes returns a zero
        // sample rate until the first buffer is pulled. Query the hardware
        // format directly (which the audio session dictates) as the primary
        // source of truth, falling back through a chain.
        var inputFormat = inputNode.inputFormat(forBus: 0)
        if inputFormat.sampleRate == 0 {
            inputFormat = inputNode.outputFormat(forBus: 0)
        }
        if inputFormat.sampleRate == 0 {
            // Last-ditch fallback — modern iPhones run at 48 kHz mono float after .voiceChat.
            inputFormat = AVAudioFormat(
                standardFormatWithSampleRate: 48000,
                channels: 1
            ) ?? inputFormat
            liveLogger.warning("⚠️ Falling back to hardcoded 48kHz mono input format")
        }

        guard inputFormat.sampleRate > 0 else {
            liveLogger.error("❌ Cannot obtain any valid mic format; aborting capture. inputFormat=\(inputFormat)")
            return
        }

        liveLogger.info("🎤 Mic format ready: \(inputFormat.sampleRate)Hz \(inputFormat.channelCount)ch commonFormat=\(inputFormat.commonFormat.rawValue)")

        // Setup converter on main actor BEFORE installing tap.
        inputConverter = AVAudioConverter(from: inputFormat, to: targetInputFormat)

        // Capture the values we need from main-isolated state so the closure is Sendable.
        let converter = inputConverter
        let target = targetInputFormat

        // Larger buffer (2048) → ~43 ms at 48 kHz → steadier sample-rate
        // conversion, fewer boundary artifacts, less CPU pressure.
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            // Running on the realtime audio thread.
            guard let self else { return }

            let rms = Self.computeRMS(buffer: buffer)
            // Snapshot the half-duplex flag without crossing the actor.
            let shouldSend = !self.suppressMicSend

            // Convert to target format (PCM16 16 kHz mono) ONLY when we'll actually send it.
            var audioData: Data?
            if shouldSend, let converter {
                let ratio = target.sampleRate / buffer.format.sampleRate
                let targetFrames = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 256

                if let converted = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: targetFrames) {
                    var provided = false
                    var error: NSError?
                    let status = converter.convert(to: converted, error: &error) { _, outStatus in
                        if provided {
                            outStatus.pointee = .noDataNow
                            return nil
                        }
                        provided = true
                        outStatus.pointee = .haveData
                        return buffer
                    }

                    if (status == .haveData || status == .inputRanDry),
                       converted.frameLength > 0,
                       let int16Channel = converted.int16ChannelData {
                        let byteCount = Int(converted.frameLength) * MemoryLayout<Int16>.size
                        audioData = Data(bytes: int16Channel[0], count: byteCount)
                    }
                }
            }

            // Send audio directly off the audio thread (no main hop) — cuts ~1
            // runloop of latency per frame. Only the UI level update goes to main.
            if let audioData {
                Task { [weak self] in
                    await self?.session?.sendAudioRealtime(audioData)
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                // Exponential smoothing so the orb doesn't jitter every 43 ms.
                self.inputAudioLevel = self.inputAudioLevel * 0.6 + rms * 0.4
                self.isUserSpeaking = self.inputAudioLevel > 0.06
            }
        }
        isMicTapInstalled = true
        liveLogger.info("🎤 Mic tap installed OK")
    }

    // MARK: - Response listener

    private func startResponseListener() {
        guard let session else { return }

        responseTask = Task { [weak self] in
            do {
                for try await message in session.responses {
                    guard let self, !Task.isCancelled else { break }

                    switch message.payload {
                    case .content(let content):
                        await self.handleServerContent(content)
                    case .goingAwayNotice:
                        liveLogger.warning("⚠️ Server sent goAway notice")
                    default:
                        break
                    }
                }
            } catch {
                liveLogger.error("❌ Response stream error: \(error.localizedDescription)")
                await MainActor.run {
                    self?.errorMessage = error.localizedDescription
                    self?.isConnected = false
                }
            }
        }
    }

    private func handleServerContent(_ content: LiveServerContent) async {
        if content.wasInterrupted {
            // Model was cut off by server-side VAD — flush playback buffer
            audioPlayerNode.stop()
            audioPlayerNode.reset()
            audioPlayerNode.play()
            isModelSpeaking = false
            outputAudioLevel = 0
            suppressMicSend = false
            return
        }

        if let modelTurn = content.modelTurn {
            for part in modelTurn.parts {
                if let inline = part as? InlineDataPart,
                   inline.mimeType.starts(with: "audio/pcm") {
                    if !isModelSpeaking {
                        isModelSpeaking = true
                        // Engage the half-duplex gate as soon as Alba starts
                        // speaking — the mic keeps running (for the orb) but
                        // we stop forwarding chunks to the server.
                        suppressMicSend = true
                    }
                    playAudioData(inline.data)
                }
            }
        }

        if content.isTurnComplete {
            isModelSpeaking = false
            outputAudioLevel = 0
            // Re-open the mic pipe for the next user turn.
            suppressMicSend = false
        }
    }

    // MARK: - Playback

    private func playAudioData(_ data: Data) {
        let bytesPerFrame = playbackFormat.streamDescription.pointee.mBytesPerFrame
        guard bytesPerFrame > 0 else { return }
        let frameCount = UInt32(data.count) / bytesPerFrame
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: playbackFormat, frameCapacity: frameCount) else {
            return
        }
        buffer.frameLength = frameCount

        data.withUnsafeBytes { raw in
            if let base = raw.baseAddress, let dst = buffer.int16ChannelData?[0] {
                memcpy(dst, base, data.count)
            }
        }

        // Publish smoothed RMS for orb so the animation doesn't jitter.
        let raw = Self.computeRMS(buffer: buffer)
        outputAudioLevel = outputAudioLevel * 0.55 + raw * 0.45

        audioPlayerNode.scheduleBuffer(buffer)
        if !audioPlayerNode.isPlaying {
            audioPlayerNode.play()
        }
    }

    // MARK: - RMS helper

    nonisolated private static func computeRMS(buffer: AVAudioPCMBuffer) -> Float {
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }

        var sum: Float = 0

        if let int16 = buffer.int16ChannelData {
            let channel = int16[0]
            for i in 0..<frames {
                let sample = Float(channel[i]) / 32768.0
                sum += sample * sample
            }
        } else if let floats = buffer.floatChannelData {
            let channel = floats[0]
            for i in 0..<frames {
                sum += channel[i] * channel[i]
            }
        } else {
            return 0
        }

        let rms = sqrt(sum / Float(frames))
        return min(1.0, rms * 3.2)
    }
}
