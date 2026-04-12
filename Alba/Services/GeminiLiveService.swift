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
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
        )
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
        try configureAudioSession()

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

        if !audioEngine.isRunning {
            try audioEngine.start()
        }

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
    }

    // MARK: - Mic Capture

    private func startMicCapture() {
        guard !isMicTapInstalled else { return }
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 else {
            liveLogger.warning("⚠️ Input node has invalid format, skipping mic capture")
            return
        }

        // Setup converter on main actor BEFORE installing tap.
        inputConverter = AVAudioConverter(from: inputFormat, to: targetInputFormat)

        // Capture the values we need from main-isolated state so the closure is Sendable.
        let converter = inputConverter
        let target = targetInputFormat

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            // Running on the realtime audio thread.
            let rms = Self.computeRMS(buffer: buffer)

            // Convert to target format (PCM16 16 kHz mono)
            var audioData: Data?
            if let converter {
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

            // Hop back to main actor with Sendable values only (Float + optional Data)
            let capturedData = audioData
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.inputAudioLevel = rms
                self.isUserSpeaking = rms > 0.08
                if let capturedData {
                    Task { [weak self] in
                        await self?.session?.sendAudioRealtime(capturedData)
                    }
                }
            }
        }
        isMicTapInstalled = true
        liveLogger.info("🎤 Mic tap installed. Input format: \(inputFormat.sampleRate)Hz \(inputFormat.channelCount)ch")
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
            return
        }

        if let modelTurn = content.modelTurn {
            for part in modelTurn.parts {
                if let inline = part as? InlineDataPart,
                   inline.mimeType.starts(with: "audio/pcm") {
                    isModelSpeaking = true
                    playAudioData(inline.data)
                }
            }
        }

        if content.isTurnComplete {
            isModelSpeaking = false
            outputAudioLevel = 0
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

        // Publish RMS for orb
        outputAudioLevel = Self.computeRMS(buffer: buffer)

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
