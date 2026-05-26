import SwiftUI

/// Compact, training-specific coach card. Splits the advice into
/// sentences and shows the first 1-2 prominently with a "Read more"
/// disclosure for the rest. Matches the app's futuristic glass DNA
/// instead of a plain flat card.
///
/// Replaces the old multi-paragraph block that often buried the
/// session-specific cue under generic guidance, athletes get the
/// "what to do today" message at a glance.
struct CoachAdviceCard: View {
    let advice: String
    let tint: Color

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [Theme.Colors.warmCoral, Theme.Colors.warmCoral.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.35), radius: 6, y: 2)
                Text("Coach")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.warmCoral)
                Spacer()
            }

            Text(displayedText)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if hasMore {
                Button(expanded ? "Show less" : "Read more") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expanded.toggle()
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.warmCoral)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.warmCoral)
    }

    // MARK: - Sentence trimming

    /// Splits advice into sentences. Default preview = first 1 (when
    /// it ends with a period) or first 2 if the first is very short.
    /// Expanded shows everything.
    private var displayedText: String {
        if expanded { return advice }
        return preview
    }

    private var sentences: [String] {
        // Naive split on ". " / "! " / "? ", keeps trailing punctuation.
        // Good enough for short coach advice; the disclosure
        // catches edge cases.
        let separators: Set<Character> = [".", "!", "?"]
        var parts: [String] = []
        var current = ""
        for ch in advice {
            current.append(ch)
            if separators.contains(ch) {
                parts.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            }
        }
        let trailing = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trailing.isEmpty { parts.append(trailing) }
        return parts.filter { !$0.isEmpty }
    }

    private var preview: String {
        let sents = sentences
        guard !sents.isEmpty else { return advice }
        // First sentence under ~80 chars → just it.
        // Otherwise → first sentence even if long (prevents weirdly
        // small previews when a single sentence runs long).
        let first = sents[0]
        if first.count >= 80 || sents.count == 1 {
            return first
        }
        // Pair up first two short sentences for a natural cadence.
        if sents.count >= 2 {
            return "\(first) \(sents[1])"
        }
        return first
    }

    private var hasMore: Bool {
        let sents = sentences
        return sents.count > 1 && preview.count < advice.count
    }
}
