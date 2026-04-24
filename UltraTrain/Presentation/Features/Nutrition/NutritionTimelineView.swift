import SwiftUI

/// Race-day timeline. Each hour is an anchored block on a vertical spine;
/// products render as large, scannable cards so the athlete can read them
/// mid-race on a phone screen while running. Futuristic-glass treatment
/// with the nutrition-domain green tint.
struct NutritionTimelineView: View {

    let entries: [NutritionEntry]

    @Environment(\.colorScheme) private var colorScheme

    private var groupedByHour: [(hour: Int, entries: [NutritionEntry])] {
        let grouped = Dictionary(grouping: entries) { $0.timingMinutes / 60 }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (hour: $0.key, entries: $0.value.sorted { $0.timingMinutes < $1.timingMinutes }) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header

            if groupedByHour.isEmpty {
                emptyTimeline
            } else {
                ForEach(Array(groupedByHour.enumerated()), id: \.element.hour) { index, group in
                    TimelineHourBlock(
                        hour: group.hour,
                        entries: group.entries,
                        isFirst: index == 0,
                        isLast: index == groupedByHour.count - 1,
                        hourCarbs: hourCarbs(for: group.entries)
                    )
                }
            }
        }
        .futuristicGlassStyle(phaseTint: NutritionPalette.tint)
    }

    private var header: some View {
        HStack {
            HStack(spacing: Theme.Spacing.xs + 2) {
                Image(systemName: "timeline.selection")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(NutritionPalette.tint)
                Text("RACE TIMELINE")
                    .font(.caption.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(NutritionPalette.tint)
            }
            Spacer()
            Text("\(entries.count) items")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var emptyTimeline: some View {
        Text("No items scheduled.")
            .font(.subheadline)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Theme.Spacing.lg)
    }

    private func hourCarbs(for entries: [NutritionEntry]) -> Int {
        Int(entries.reduce(0.0) { $0 + $1.product.carbsGramsPerServing * Double($1.quantity) })
    }
}

// MARK: - Hour Block

private struct TimelineHourBlock: View {
    let hour: Int
    let entries: [NutritionEntry]
    let isFirst: Bool
    let isLast: Bool
    let hourCarbs: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm + 2) {
            spine
            content
        }
    }

    private var spine: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(NutritionPalette.tint.opacity(isFirst ? 0 : 0.25))
                .frame(width: 2, height: 14)
            ZStack {
                Circle()
                    .fill(NutritionPalette.gradient)
                    .frame(width: 14, height: 14)
                    .shadow(color: NutritionPalette.tint.opacity(0.4), radius: 4, y: 2)
                Circle()
                    .stroke(NutritionPalette.tint.opacity(0.25), lineWidth: 4)
                    .frame(width: 22, height: 22)
            }
            Rectangle()
                .fill(NutritionPalette.tint.opacity(isLast ? 0 : 0.25))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 22)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            hourHeader
            ForEach(entries) { entry in
                NutritionProductCard(entry: entry)
            }
        }
        .padding(.bottom, Theme.Spacing.md)
    }

    private var hourHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Hour \(hour + 1)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.Colors.label)
                Text("\(hour * 60)–\((hour + 1) * 60) min")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
            Spacer()
            Text("\(hourCarbs) g")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(NutritionPalette.tint)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(NutritionPalette.tint.opacity(0.12))
                )
                .overlay(
                    Capsule().stroke(NutritionPalette.tint.opacity(0.25), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Product card

struct NutritionProductCard: View {
    let entry: NutritionEntry

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm + 2) {
            iconBadge
            VStack(alignment: .leading, spacing: 4) {
                productTitle
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                microstats
            }
            Spacer(minLength: 0)
            timingBadge
        }
        .padding(Theme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.05)
                      : Color.white.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(entry.product.type.color.opacity(0.25), lineWidth: 0.75)
        )
        .overlay(
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(entry.product.type.color)
                    .frame(width: 4)
                    .padding(.vertical, 10)
                Spacer()
            }
            .padding(.leading, 4)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(entry.product.type.color.opacity(0.18))
                .frame(width: 40, height: 40)
            Image(systemName: entry.product.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(entry.product.type.color)
        }
        .padding(.leading, 4)
    }

    private var productTitle: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let brand = entry.product.brand, !brand.isEmpty {
                Text(brand.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(entry.product.type.color)
                    .tracking(0.8)
            }
            Text(entry.product.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(2)
        }
    }

    private var microstats: some View {
        HStack(spacing: Theme.Spacing.sm + 2) {
            if entry.product.carbsGramsPerServing > 0 {
                microstat(value: "\(Int(entry.product.carbsGramsPerServing))g", label: "carbs")
            }
            if entry.product.sodiumMgPerServing > 0 {
                microstat(value: "\(entry.product.sodiumMgPerServing)mg", label: "Na")
            }
            if entry.product.caffeineMgPerServing > 0 {
                microstat(value: "\(entry.product.caffeineMgPerServing)mg", label: "caf")
            }
            if let fluid = entry.product.fluidMlPerServing, fluid > 0 {
                microstat(value: "\(fluid)ml", label: "water")
            }
        }
        .padding(.top, 2)
    }

    private func microstat(value: String, label: String) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.Colors.label)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.tertiaryLabel)
        }
    }

    private var timingBadge: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(formattedTime)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var formattedTime: String {
        let h = entry.timingMinutes / 60
        let m = entry.timingMinutes % 60
        if h == 0 { return "\(m)min" }
        return String(format: "%dh%02d", h, m)
    }

    private var accessibilityLabel: String {
        var parts: [String] = []
        if let brand = entry.product.brand { parts.append(brand) }
        parts.append(entry.product.name)
        parts.append("at \(formattedTime)")
        if entry.product.carbsGramsPerServing > 0 {
            parts.append("\(Int(entry.product.carbsGramsPerServing)) grams carbs")
        }
        if let notes = entry.notes { parts.append(notes) }
        return parts.joined(separator: ", ")
    }
}
