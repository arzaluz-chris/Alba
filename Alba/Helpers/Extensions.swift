import SwiftUI

// MARK: - Rounded Corner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Pronoun Replacement (English)
extension String {
    func replacingPronounWord(_ word: String, with replacement: String) -> String {
        let pattern = "(?i)(?<![A-Za-z])" + NSRegularExpression.escapedPattern(for: word) + "(?![A-Za-z'])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }

        var result = self
        let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)
        let matches = regex.matches(in: result, range: nsRange)

        for match in matches.reversed() {
            guard let r = Range(match.range, in: result) else { continue }
            let matched = String(result[r])
            let repl = replacement.applyingCaseLike(matched)
            result.replaceSubrange(r, with: repl)
        }
        return result
    }

    private func applyingCaseLike(_ template: String) -> String {
        if template == template.uppercased() { return uppercased() }
        if let first = template.first, String(first) == String(first).uppercased() {
            return capitalizingFirstLetter()
        }
        return lowercased()
    }

    private func capitalizingFirstLetter() -> String {
        guard let first = self.first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
    }

    func premiumShadow(color: Color = .black, opacity: Double = 0.1, radius: CGFloat = 20) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 10)
    }
}
