import SwiftUI

struct SuggestionChipsView: View {
    let suggestions: [String]
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { text in
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        onTap(text)
                    }) {
                        Text(text)
                            .font(AlbaFont.rounded(13, weight: .medium))
                            .foregroundColor(.albaAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.albaAccent.opacity(0.25), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
