import SwiftUI

/// Visual race-day timeline replacing the list-based schedule. Each hour is
/// a labeled block on a vertical spine; products for that hour render as
/// rich cards with type-colored left border, brand, product name, timing,
/// and a microstats row (carbs / sodium / caffeine / fluid).
struct NutritionTimelineView: View {

    let entries: [NutritionEntry]

    private var groupedByHour: [(hour: Int, entries: [NutritionEntry])] {
        let grouped = Dictionary(grouping: entries) { $0.timingMinutes / 60 }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (hour: $0.key, entries: $0.value.sorted { $0.timingMinutes < $1.timingMinutes }) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Label("Race timeline", systemImage: "timeline.selection")
                    .font(.headline)
                Spacer()
                Text("\(entries.count) items")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

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

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Spine + hour marker
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.Colors.accentColor.opacity(isFirst ? 0 : 0.2))
                    .frame(width: 2, height: 10)
                Circle()
                    .fill(Theme.Colors.accentColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.accentColor.opacity(0.25), lineWidth: 4)
                    )
                Rectangle()
                    .fill(Theme.Colors.accentColor.opacity(isLast ? 0 : 0.2))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 12)

            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Hour \(hour + 1)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.Colors.accentColor)
                    Text("\(hour * 60)–\((hour + 1) * 60) min")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Spacer()
                    Text("\(hourCarbs) g carbs")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Theme.Colors.accentColor.opacity(0.08))
                        )
                }

                ForEach(entries) { entry in
                    NutritionProductCard(entry: entry)
                }
            }
            .padding(.bottom, Theme.Spacing.md)
        }
    }
}

// MARK: - Product card (rich entry)

struct NutritionProductCard: View {
    let entry: NutritionEntry

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Type-colored icon badge
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
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .overlay(
            HStack(spacing: 0) {
                Rectangle()
                    .fill(entry.product.type.color)
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Sections

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(entry.product.type.color.opacity(0.18))
                .frame(width: 36, height: 36)
            Image(systemName: entry.product.type.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(entry.product.type.color)
        }
    }

    private var productTitle: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let brand = entry.product.brand, !brand.isEmpty {
                Text(brand.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(entry.product.type.color)
                    .tracking(0.5)
            }
            Text(entry.product.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(2)
        }
    }

    private var microstats: some View {
        HStack(spacing: Theme.Spacing.sm) {
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
                .font(.caption2.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Theme.Colors.tertiaryLabel)
        }
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    private var timingBadge: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(formattedTime)
                .font(.caption.weight(.semibold).monospacedDigit())
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
