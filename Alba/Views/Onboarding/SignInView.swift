import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Binding var currentView: AppState
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showError = false

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                Image("ALBA_LOGO")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.albaAccent.opacity(0.3), radius: 20)

                Text("Alba")
                    .font(AlbaFont.serif(36, weight: .heavy))
                    .foregroundColor(.albaText)

                // Glass card
                VStack(spacing: 20) {
                    Text(languageManager.language == .es ? "Bienvenido a Alba" : "Welcome to Alba")
                        .font(AlbaFont.serif(22, weight: .bold))
                        .foregroundColor(.albaText)

                    Text(L10n.t(.signInSubtitle, languageManager.language))
                        .font(AlbaFont.rounded(14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            authManager.handleAuthorization(auth)
                            withAnimation { currentView = .onboarding }
                        case .failure:
                            showError = true
                            HapticManager.shared.notification(.error)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showError = false }
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                    if showError {
                        Text(languageManager.language == .es ? "No se pudo iniciar sesión" : "Sign in failed")
                            .font(AlbaFont.caption())
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }
                }
                .padding(28)
                .glassCard(cornerRadius: 28)
                .padding(.horizontal, 30)

                // Skip button
                Button(action: {
                    withAnimation(.easeInOut) { currentView = .onboarding }
                }) {
                    Text(languageManager.language == .es ? "Continuar sin cuenta" : "Continue without account")
                        .font(AlbaFont.rounded(14, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                }

                Spacer()
                Spacer()
            }
        }
    }
}
