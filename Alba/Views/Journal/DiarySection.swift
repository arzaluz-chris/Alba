import SwiftUI

struct DiarySection: View {
    let friendName: String
    @EnvironmentObject var languageManager: LanguageManager

    @State private var entries: [JournalEntry] = []
    @State private var showCompose: Bool = false
    @State private var entryToEdit: JournalEntry? = nil
    @State private var entryToDelete: JournalEntry? = nil
    @State private var showDeleteConfirm: Bool = false

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(lang == .es ? "Diario" : "Diary")
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)

                Spacer()

                NavigationLink {
                    JournalEntryComposeView(friendName: friendName)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(LinearGradient.albaAccentGradient)
                }
            }

            if entries.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.4))
                    Text(lang == .es
                         ? "Aún no hay entradas. Escribe algo sobre esta amistad."
                         : "No entries yet. Write something about this friendship.")
                        .font(AlbaFont.rounded(14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(entries.prefix(5)) { entry in
                    entryRow(entry)
                        .onTapGesture {
                            entryToEdit = entry
                        }
                        .contextMenu {
                            Button {
                                entryToEdit = entry
                            } label: {
                                Label(lang == .es ? "Editar" : "Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                entryToDelete = entry
                                showDeleteConfirm = true
                            } label: {
                                Label(lang == .es ? "Eliminar" : "Delete", systemImage: "trash")
                            }
                        }
                }

                if entries.count > 5 {
                    Text(lang == .es
                         ? "\(entries.count - 5) entradas más..."
                         : "\(entries.count - 5) more entries...")
                        .font(AlbaFont.rounded(12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.3), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .onAppear { loadEntries() }
        .onChange(of: showCompose) { loadEntries() }
        .sheet(item: $entryToEdit) { entry in
            NavigationStack {
                JournalEntryComposeView(friendName: friendName, existingEntry: entry)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(lang == .es ? "Cancelar" : "Cancel") {
                                entryToEdit = nil
                            }
                            .foregroundColor(.albaAccent)
                        }
                    }
            }
            .environmentObject(languageManager)
            .onDisappear { loadEntries() }
        }
        .alert(
            lang == .es ? "¿Eliminar entrada?" : "Delete entry?",
            isPresented: $showDeleteConfirm
        ) {
            Button(lang == .es ? "Cancelar" : "Cancel", role: .cancel) {
                entryToDelete = nil
            }
            Button(lang == .es ? "Eliminar" : "Delete", role: .destructive) {
                if let entry = entryToDelete {
                    JournalEntryStore.shared.delete(entryId: entry.id)
                    HapticManager.shared.notification(.warning)
                    loadEntries()
                }
                entryToDelete = nil
            }
        } message: {
            Text(lang == .es
                 ? "Esta acción no se puede deshacer."
                 : "This action cannot be undone.")
        }
    }

    private func entryRow(_ entry: JournalEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Mood icon
            if let mood = entry.mood {
                Image(systemName: mood.icon)
                    .font(.system(size: 16))
                    .foregroundColor(moodColor(mood))
                    .frame(width: 24)
            } else {
                Image(systemName: "note.text")
                    .font(.system(size: 16))
                    .foregroundColor(.gray.opacity(0.5))
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayDate)
                    .font(AlbaFont.rounded(12, weight: .medium))
                    .foregroundColor(.gray)

                Text(entry.text)
                    .font(AlbaFont.rounded(14))
                    .foregroundColor(.albaText)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func moodColor(_ mood: JournalMood) -> Color {
        switch mood {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }

    private func loadEntries() {
        entries = JournalEntryStore.shared.entries(for: friendName)
    }
}
