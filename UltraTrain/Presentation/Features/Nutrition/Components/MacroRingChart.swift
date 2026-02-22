import SwiftUI

struct MacroRingChart: View {
    let caloriesConsumed: Int
    let caloriesTarget: Int
    let carbsConsumed: Double
    let carbsTarget: Int
    let proteinConsumed: Double
    let proteinTarget: Int
    let fatConsumed: Double
    let fatTarget: Int

    private var calorieProgress: Double {
        guard caloriesTarget > 0 else { return 0 }
        return min(Double(caloriesConsumed) / Double(caloriesTarget), 1.0)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            calorieRing
            macroProgressBars
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("nutrition.macroRingChart")
    }

    // MARK: - Calorie Ring

    private var calorieRing: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.secondaryLabel.opacity(0.2), lineWidth: 14)

            Circle()
                .trim(from: 0, to: calorieProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: calorieProgress)

            VStack(spacing: Theme.Spacing.xs) {
                Text("\(caloriesConsumed)")
                    .font(.title.bold())
                    .foregroundStyle(Theme.Colors.label)
                Text("of \(caloriesTarget) kcal")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 160, height: 160)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(caloriesConsumed) of \(caloriesTarget) calories consumed"
        )
        .accessibilityValue("\(Int(calorieProgress * 100)) percent")
    }

    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [Theme.Colors.primary, Theme.Colors.success]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * calorieProgress)
        )
    }

    // MARK: - Macro Bars

    private var macroProgressBars: some View {
        VStack(spacing: Theme.Spacing.sm) {
            macroBar(
                label: "Carbs",
                consumed: carbsConsumed,
                target: Double(carbsTarget),
                color: .blue
            )
            macroBar(
                label: "Protein",
                consumed: proteinConsumed,
                target: Double(proteinTarget),
                color: .green
            )
            macroBar(
                label: "Fat",
                consumed: fatConsumed,
                target: Double(fatTarget),
                color: .orange
            )
        }
    }

    private func macroBar(
        label: String,
        consumed: Double,
        target: Double,
        color: Color
    ) -> some View {
        let progress = target > 0 ? min(consumed / target, 1.0) : 0
        let percentage = Int(progress * 100)

        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Text("\(Int(consumed))g / \(Int(target))g (\(percentage)%)")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * progress,
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(Int(consumed)) of \(Int(target)) grams")
        .accessibilityValue("\(percentage) percent")
    }
}
