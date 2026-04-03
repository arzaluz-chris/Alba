import SwiftUI
import LocalAuthentication

struct PINEntryView: View {
    enum Mode {
        case create, confirm, unlock
    }

    let mode: Mode
    let onComplete: (String) -> Void
    var onBiometric: (() -> Void)?

    @EnvironmentObject var languageManager: LanguageManager
    @State private var enteredDigits: String = ""
    @State private var shake: Bool = false

    private var lang: AppLanguage { languageManager.language }

    private var title: String {
        switch mode {
        case .create:
            return lang == .es ? "Crea un PIN de 4 dígitos" : "Create a 4-digit PIN"
        case .confirm:
            return lang == .es ? "Confirma tu PIN" : "Confirm your PIN"
        case .unlock:
            return lang == .es ? "Ingresa tu PIN" : "Enter your PIN"
        }
    }

    var body: some View {
        ZStack {
            Color.albaBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Lock icon
                Image(systemName: mode == .unlock ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.albaAccent)

                // Title
                Text(title)
                    .font(AlbaFont.serif(22, weight: .bold))
                    .foregroundColor(.albaText)

                // PIN dots
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < enteredDigits.count ? Color.albaAccent : Color.gray.opacity(0.2))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(Color.albaAccent.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .offset(x: shake ? -10 : 0)

                Spacer().frame(height: 20)

                // Number pad
                VStack(spacing: 14) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 24) {
                            ForEach(1...3, id: \.self) { col in
                                let number = row * 3 + col
                                pinButton("\(number)") { appendDigit("\(number)") }
                            }
                        }
                    }

                    // Bottom row: biometric, 0, delete
                    HStack(spacing: 24) {
                        if mode == .unlock, let onBiometric {
                            Button {
                                onBiometric()
                            } label: {
                                Image(systemName: biometricIcon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.albaAccent)
                                    .frame(width: 70, height: 70)
                            }
                        } else {
                            Color.clear.frame(width: 70, height: 70)
                        }

                        pinButton("0") { appendDigit("0") }

                        Button {
                            if !enteredDigits.isEmpty {
                                enteredDigits.removeLast()
                                HapticManager.shared.lightImpact()
                            }
                        } label: {
                            Image(systemName: "delete.backward")
                                .font(.system(size: 22))
                                .foregroundColor(.albaText)
                                .frame(width: 70, height: 70)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }

    private var biometricIcon: String {
        let type = JournalSecurityManager.shared.biometricType
        return type == .faceID ? "faceid" : "touchid"
    }

    private func pinButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AlbaFont.rounded(28, weight: .semibold))
                .foregroundColor(.albaText)
                .frame(width: 70, height: 70)
                .background(Color.albaSurface.opacity(0.6))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
    }

    private func appendDigit(_ digit: String) {
        guard enteredDigits.count < 4 else { return }
        HapticManager.shared.lightImpact()
        enteredDigits += digit

        if enteredDigits.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onComplete(enteredDigits)
            }
        }
    }

    func triggerShake() {
        withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
            shake = true
        }
        HapticManager.shared.notification(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            shake = false
            enteredDigits = ""
        }
    }
}
