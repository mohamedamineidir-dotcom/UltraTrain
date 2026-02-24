import SwiftUI

struct ParticipantAnnotationView: View {
    let name: String
    let paceSecondsPerKm: Double
    let lastUpdated: Date

    @ScaledMetric(relativeTo: .caption2) private var nameFontSize: CGFloat = 9
    @ScaledMetric(relativeTo: .caption2) private var detailFontSize: CGFloat = 8

    private var clampedNameSize: CGFloat { min(nameFontSize, 14) }
    private var clampedDetailSize: CGFloat { min(detailFontSize, 12) }

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .shadow(radius: 1)

            Text(name)
                .font(.system(size: clampedNameSize, weight: .semibold))
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(1)

            Text(formattedPace)
                .font(.system(size: clampedDetailSize))
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(2)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), pace \(formattedPace)\(isStale ? ", location stale" : "")")
    }

    // MARK: - Color Coding

    private var isStale: Bool {
        Date.now.timeIntervalSince(lastUpdated) > 300
    }

    private var dotColor: Color {
        if isStale { return .gray }
        switch paceSecondsPerKm {
        case ..<420: return Theme.Colors.success    // < 7:00 /km
        case 420..<600: return Theme.Colors.primary // 7:00 - 10:00
        default: return .orange                     // > 10:00
        }
    }

    // MARK: - Formatting

    private var formattedPace: String {
        guard paceSecondsPerKm > 0 else { return "--:--" }
        let minutes = Int(paceSecondsPerKm) / 60
        let seconds = Int(paceSecondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
