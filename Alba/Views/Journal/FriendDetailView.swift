import SwiftUI

struct FriendDetailView: View {
    let friendName: String
    var onNavigate: ((AppState) -> Void)?
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var records: [FriendshipRecord] = []

    private var lang: AppLanguage { languageManager.language }
    private var latest: FriendshipRecord? { records.first }

    private let permaCategories: [(key: String, labelEs: String, labelEn: String, icon: String)] = [
        ("support", "Apoyo", "Support", "hand.raised.fill"),
        ("trust", "Confianza", "Trust", "lock.shield.fill"),
        ("limits", "Limites", "Boundaries", "hand.raised.slash.fill"),
        ("assertiveness", "Asertividad", "Assertiveness", "bubble.left.and.exclamationmark.bubble.right.fill")
    ]

    var body: some View {
        ZStack {
            Color.albaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Friend header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.albaAccent.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(String(friendName.prefix(1)).uppercased())
                                .font(AlbaFont.serif(36, weight: .bold))
                                .foregroundColor(.albaAccent)
                        }
                        Text(friendName)
                            .font(AlbaFont.serif(28, weight: .bold))
                            .foregroundColor(.albaText)

                        if let latest {
                            Text(latest.rating)
                                .font(AlbaFont.rounded(14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(ratingColor(latest.overallScore)))
                        }
                    }
                    .padding(.top, 20)

                    // MARK: - Action Buttons
                    HStack(spacing: 12) {
                        // Re-evaluate button
                        Button {
                            HapticManager.shared.mediumImpact()
                            dismiss()
                            let gender = Gender(rawValue: latest?.friendGender ?? "chico") ?? .chico
                            onNavigate?(.reEvaluate(friendName: friendName, friendGender: gender))
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(lang == .es ? "Re-evaluar" : "Re-evaluate")
                                    .font(AlbaFont.rounded(14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(LinearGradient.albaAccentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.albaAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        // Chat with Alba button
                        Button {
                            HapticManager.shared.mediumImpact()
                            let context = lang == .es
                                ? "Quiero hablar sobre mi amistad con \(friendName). Mis resultados mas recientes: \(latest?.rating ?? "sin evaluar"), area de enfoque: \(latest?.focusArea ?? "ninguna")."
                                : "I want to talk about my friendship with \(friendName). My latest results: \(latest?.rating ?? "not evaluated"), focus area: \(latest?.focusArea ?? "none")."
                            dismiss()
                            onNavigate?(.chat(initialContext: context))
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.text.bubble.right")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(lang == .es ? "Hablar con Alba" : "Talk to Alba")
                                    .font(AlbaFont.rounded(14, weight: .bold))
                            }
                            .foregroundColor(.albaAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.albaAccent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.albaAccent.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Days since last eval warning
                    if let days = FriendshipStore.shared.daysSinceLastTest(for: friendName), days > 14 {
                        Button {
                            HapticManager.shared.mediumImpact()
                            dismiss()
                            let gender = Gender(rawValue: latest?.friendGender ?? "chico") ?? .chico
                            onNavigate?(.reEvaluate(friendName: friendName, friendGender: gender))
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lang == .es
                                         ? "Han pasado \(days) dias"
                                         : "It's been \(days) days")
                                        .font(AlbaFont.rounded(14, weight: .bold))
                                        .foregroundColor(.albaText)
                                    Text(lang == .es
                                         ? "Toca para re-evaluar esta amistad"
                                         : "Tap to re-evaluate this friendship")
                                        .font(AlbaFont.rounded(12))
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.orange.opacity(0.6))
                            }
                            .padding(14)
                            .background(Color.orange.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }

                    // PERMA Chart
                    VStack(alignment: .leading, spacing: 14) {
                        Text("PERMA")
                            .font(AlbaFont.serif(20, weight: .bold))
                            .foregroundColor(.albaText)

                        ForEach(permaCategories, id: \.key) { cat in
                            let score = latest?.categoryScores[cat.key] ?? 0
                            let trend = FriendshipStore.shared.trend(for: friendName, category: cat.key)

                            HStack(spacing: 12) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(.albaAccent)
                                    .frame(width: 24)

                                Text(lang == .es ? cat.labelEs : cat.labelEn)
                                    .font(AlbaFont.rounded(14, weight: .medium))
                                    .foregroundColor(.albaText)
                                    .frame(width: 90, alignment: .leading)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.15))
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(barColor(score))
                                            .frame(width: geo.size.width * (score / 3.0))
                                    }
                                }
                                .frame(height: 12)

                                Text(String(format: "%.1f", score))
                                    .font(AlbaFont.rounded(13, weight: .bold))
                                    .foregroundColor(.albaText)
                                    .frame(width: 30)

                                if let trend {
                                    Image(systemName: trend > 0 ? "arrow.up.circle.fill" : (trend < 0 ? "arrow.down.circle.fill" : "minus.circle.fill"))
                                        .font(.system(size: 16))
                                        .foregroundColor(trend > 0 ? .green : (trend < 0 ? .red : .gray))
                                } else {
                                    Image(systemName: "minus.circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.3), lineWidth: 0.8))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    // History
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang == .es ? "Historial" : "History")
                            .font(AlbaFont.serif(20, weight: .bold))
                            .foregroundColor(.albaText)

                        ForEach(records) { record in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.displayDate)
                                        .font(AlbaFont.rounded(14, weight: .medium))
                                        .foregroundColor(.albaText)
                                    Text(record.rating)
                                        .font(AlbaFont.rounded(12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(String(format: "%.1f", record.overallScore))
                                    .font(AlbaFont.rounded(18, weight: .bold))
                                    .foregroundColor(ratingColor(record.overallScore))
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.3), lineWidth: 0.8))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(friendName)
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)
            }
        }
        .onAppear {
            records = FriendshipStore.shared.recordsFor(friend: friendName)
        }
    }

    private func barColor(_ score: Double) -> Color {
        if score >= 2.5 { return .green.opacity(0.7) }
        else if score >= 2.0 { return .orange.opacity(0.7) }
        else { return .red.opacity(0.7) }
    }

    private func ratingColor(_ score: Double) -> Color {
        if score >= 2.8 { return Color.green }
        else if score <= 1.8 { return Color.red }
        else { return Color.orange }
    }
}
