import SwiftUI

struct JournalView: View {
    @Binding var currentView: AppState
    @EnvironmentObject var languageManager: LanguageManager

    @State private var records: [FriendshipRecord] = []
    @State private var uniqueFriends: [String] = []
    @State private var friendToDelete: String? = nil
    @State private var showDeleteConfirm: Bool = false

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
                        Text(lang == .es ? "Aún no has evaluado ninguna amistad" : "You haven't evaluated any friendships yet")
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
                                .contextMenu {
                                    Button(role: .destructive) {
                                        friendToDelete = friend
                                        showDeleteConfirm = true
                                    } label: {
                                        Label(lang == .es ? "Eliminar amistad" : "Delete friendship", systemImage: "trash")
                                    }
                                }
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
        .alert(
            lang == .es ? "¿Eliminar amistad?" : "Delete friendship?",
            isPresented: $showDeleteConfirm
        ) {
            Button(lang == .es ? "Cancelar" : "Cancel", role: .cancel) {
                friendToDelete = nil
            }
            Button(lang == .es ? "Eliminar" : "Delete", role: .destructive) {
                if let name = friendToDelete {
                    FriendshipStore.shared.deleteFriend(name: name)
                    JournalEntryStore.shared.entries(for: name).forEach {
                        JournalEntryStore.shared.delete(entryId: $0.id)
                    }
                    HapticManager.shared.notification(.warning)
                    uniqueFriends = FriendshipStore.shared.uniqueFriends()
                    records = FriendshipStore.shared.loadAll()
                    friendToDelete = nil
                }
            }
        } message: {
            Text(lang == .es
                 ? "Se eliminarán todas las evaluaciones y entradas de diario de \(friendToDelete ?? ""). Esta acción no se puede deshacer."
                 : "All evaluations and diary entries for \(friendToDelete ?? "") will be deleted. This action cannot be undone.")
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

                Text(lang == .es ? "\(count) evaluación\(count == 1 ? "" : "es")" : "\(count) evaluation\(count == 1 ? "" : "s")")
                    .font(AlbaFont.rounded(12))
                    .foregroundColor(.gray.opacity(0.7))
            }

            Spacer()

            // Rating badge
            if let latest {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(latest.rating)
                        .font(AlbaFont.rounded(13, weight: .bold))
                        .foregroundColor(scoreColor(latest.overallScore))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .frame(maxWidth: 110)
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
