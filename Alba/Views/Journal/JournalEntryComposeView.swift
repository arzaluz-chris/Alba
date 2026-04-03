import SwiftUI

struct JournalEntryComposeView: View {
    let friendName: String
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextEditorFocused: Bool

    @State private var text: String = ""
    @State private var selectedMood: JournalMood? = nil
    @State private var entryDate: Date = Date()
    @State private var showDatePicker: Bool = false

    private var lang: AppLanguage { languageManager.language }

    var body: some View {
        ZStack {
            Color.albaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Mood + Date row
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang == .es ? "¿Cómo te sientes?" : "How are you feeling?")
                            .font(AlbaFont.rounded(14, weight: .medium))
                            .foregroundColor(.albaText)

                        HStack(spacing: 10) {
                            ForEach(JournalMood.allCases) { mood in
                                Button {
                                    HapticManager.shared.lightImpact()
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedMood = selectedMood == mood ? nil : mood
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: mood.icon)
                                            .font(.system(size: 22))
                                        Text(mood.label(for: lang))
                                            .font(AlbaFont.rounded(11))
                                    }
                                    .foregroundColor(selectedMood == mood ? .white : .albaText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        Group {
                                            if selectedMood == mood {
                                                LinearGradient.albaAccentGradient
                                            } else {
                                                Color.albaSurface.opacity(0.8)
                                            }
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedMood == mood ? Color.clear : Color.white.opacity(0.3), lineWidth: 0.8)
                                    )
                                }
                            }

                            // Date button matching mood style exactly
                            Button {
                                showDatePicker = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 22))
                                    Text(entryDate.formatted(.dateTime.day().month(.abbreviated)))
                                        .font(AlbaFont.rounded(11))
                                }
                                .foregroundColor(.albaText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.albaSurface.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Text editor
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang == .es ? "Escribe sobre esta amistad" : "Write about this friendship")
                            .font(AlbaFont.rounded(14, weight: .medium))
                            .foregroundColor(.albaText)

                        TextEditor(text: $text)
                            .font(AlbaFont.rounded(16))
                            .foregroundColor(.albaText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                            .padding(14)
                            .background(Color.albaSurface.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                            )
                            .focused($isTextEditorFocused)
                    }
                    .padding(.horizontal, 20)

                    // Save button
                    Button {
                        saveEntry()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(lang == .es ? "Guardar" : "Save")
                                .font(AlbaFont.rounded(16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient.albaAccentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.albaAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 20)
                }
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(lang == .es ? "Nueva entrada" : "New entry")
                    .font(AlbaFont.serif(20, weight: .bold))
                    .foregroundColor(.albaText)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(lang == .es ? "Listo" : "Done") {
                    isTextEditorFocused = false
                }
                .font(AlbaFont.rounded(15, weight: .semibold))
                .foregroundColor(.albaAccent)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 16) {
                Text(lang == .es ? "Selecciona la fecha" : "Select date")
                    .font(AlbaFont.serif(18, weight: .bold))
                    .foregroundColor(.albaText)
                    .padding(.top, 20)

                DatePicker("", selection: $entryDate, in: ...Date(), displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .tint(.albaAccent)
                    .padding(.horizontal)

                Button {
                    showDatePicker = false
                } label: {
                    Text(lang == .es ? "Listo" : "Done")
                        .font(AlbaFont.rounded(16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.albaAccentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .presentationDetents([.medium])
        }
    }

    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        HapticManager.shared.mediumImpact()

        let entry = JournalEntry(
            date: entryDate,
            friendName: friendName,
            text: trimmed,
            mood: selectedMood
        )
        JournalEntryStore.shared.save(entry: entry)
        dismiss()
    }
}
