import SwiftUI

struct JournalView: View {
    @Binding var currentView: AppState
    @EnvironmentObject var languageManager: LanguageManager

    @State private var records: [FriendshipRecord] = []
    @State private var uniqueFriends: [String] = []

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        HapticManager.shared.lightImpact()
                        currentView = .welcome
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.albaText)
                    }
                    Spacer()
                    Text(lang == .es ? "Mi Journal" : "My Journal")
                        .font(AlbaFont.serif(20, weight: .bold))
                        .foregroundColor(.albaText)
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0) // balance
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)

                if uniqueFriends.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.albaAccent.opacity(0.4))
                        Text(lang == .es ? "Aun no has evaluado ninguna amistad" : "You haven't evaluated any friendships yet")
                            .font(AlbaFont.rounded(16, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        GlassActionButton(lang == .es ? "Hacer mi primer test" : "Take my first test", icon: "checklist", style: .primary) {
                            currentView = .albaTest
                        }
                        .frame(maxWidth: 260)
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(uniqueFriends, id: \.self) { friend in
                                NavigationLink {
                                    FriendDetailView(friendName: friend) { state in
                                        currentView = state
                                    }
                                } label: {
                                    friendCard(friend)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            records = FriendshipStore.shared.loadAll()
            uniqueFriends = FriendshipStore.shared.uniqueFriends()
        }
    }

    private func friendCard(_ friend: String) -> some View {
        let latest = FriendshipStore.shared.latestRecord(for: friend)
        let count = FriendshipStore.shared.recordsFor(friend: friend).count

        return HStack(spacing: 14) {
            // Avatar circle with first letter
            ZStack {
                Circle()
                    .fill(Color.albaAccent.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(String(friend.prefix(1)).uppercased())
                    .font(AlbaFont.serif(22, weight: .bold))
                    .foregroundColor(.albaAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(friend)
                    .font(AlbaFont.rounded(17, weight: .semibold))
                    .foregroundColor(.albaText)

                if let latest {
                    Text(latest.displayDate)
                        .font(AlbaFont.rounded(13))
                        .foregroundColor(.gray)
                }

                Text(lang == .es ? "\(count) evaluacion\(count == 1 ? "" : "es")" : "\(count) evaluation\(count == 1 ? "" : "s")")
                    .font(AlbaFont.rounded(12))
                    .foregroundColor(.gray.opacity(0.7))
            }

            Spacer()

            // Rating badge
            if let latest {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", latest.overallScore))
                        .font(AlbaFont.rounded(20, weight: .bold))
                        .foregroundColor(scoreColor(latest.overallScore))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 2.8 { return .green }
        else if score <= 1.8 { return .red }
        else { return .orange }
    }
}
