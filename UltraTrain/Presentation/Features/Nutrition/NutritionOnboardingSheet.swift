import SwiftUI

/// Domain-specific colour palette for the nutrition onboarding.
/// Uses a clean mint-to-teal green range — reads "nutrition / fresh /
/// clean" rather than the app's warm-coral brand accent which sits
/// better on training surfaces. Kept private so this doesn't leak
/// into general theme decisions; it's a one-surface palette.
private enum NutritionOnboardingTheme {
    static let tint = Color(red: 0.18, green: 0.72, blue: 0.55)
    static let deep = Color(red: 0.12, green: 0.54, blue: 0.40)
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.22, green: 0.78, blue: 0.60),
            Color(red: 0.14, green: 0.58, blue: 0.42)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Pre-plan nutrition onboarding sheet. Presented before "Generate Plan"
/// on the Race Day tab.
///
/// Redesigned as a step-by-step flow (one question per screen, big
/// tappable cards) instead of a long scrollable form. Matches the main
/// onboarding aesthetic: coral-gradient icon header, progress bar,
/// Back/Next navigation. The athlete's goal is DERIVED from the A-race
/// `goalType` — we don't ask again for what onboarding already knows.
///
/// Steps are gated by race distance:
///   • Always: caffeine, dietary restrictions
///   • Half marathon and up: GI sensitivities, preferred formats
///   • Marathon and up: optional advanced profile (carbs tolerance,
///     sweat rate + sodium, heavy-salty-sweater flag)
struct NutritionOnboardingSheet: View {

    let raceName: String
    let raceDistanceKm: Double
    /// Used to derive `nutritionGoal` from what onboarding captured.
    let raceGoalType: RaceGoal
    let initialPreferences: NutritionPreferences
    let onGenerate: (NutritionPreferences) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var preferences: NutritionPreferences
    @State private var stepIndex: Int = 0
    @State private var carbsToleranceText: String = ""
    @State private var sweatRateText: String = ""
    @State private var sweatSodiumText: String = ""

    init(
        raceName: String,
        raceDistanceKm: Double,
        raceGoalType: RaceGoal,
        initialPreferences: NutritionPreferences,
        onGenerate: @escaping (NutritionPreferences) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.raceName = raceName
        self.raceDistanceKm = raceDistanceKm
        self.raceGoalType = raceGoalType
        self.initialPreferences = initialPreferences
        self.onGenerate = onGenerate
        self.onCancel = onCancel
        var prefs = initialPreferences
        // Derive the nutrition goal from the A-race goal type — no need
        // to re-ask what onboarding already captured. Maps:
        //   .finish          → conservative (finishComfortably)
        //   .targetTime(_)   → standard evidence-based (targetTime)
        //   .targetRanking(_)→ aggressive / competitive
        switch raceGoalType {
        case .finish:            prefs.nutritionGoal = .finishComfortably
        case .targetTime:        prefs.nutritionGoal = .targetTime
        case .targetRanking:     prefs.nutritionGoal = .competitive
        }
        _preferences = State(initialValue: prefs)
    }

    // MARK: - Gating

    private var needsExtendedQuestions: Bool { raceDistanceKm >= 18 }
    private var needsAdvancedQuestions: Bool { raceDistanceKm >= 35 }

    fileprivate enum Step: Int, CaseIterable {
        case caffeine
        case dietary
        case giSensitivities
        case formats
        case advanced

        var title: String {
            switch self {
            case .caffeine:         return "How much caffeine?"
            case .dietary:          return "Anything to avoid?"
            case .giSensitivities:  return "Any stomach trouble in past races?"
            case .formats:          return "What do you like to fuel with?"
            case .advanced:         return "Any training data to calibrate?"
            }
        }

        var subtitle: String {
            switch self {
            case .caffeine:
                return "We use this to calibrate race-day dose."
            case .dietary:
                return "We'll only suggest products that fit."
            case .giSensitivities:
                return "Things that have caused issues before — gels, fructose, gluten..."
            case .formats:
                return "Tap every format you're happy to use on race day."
            case .advanced:
                return "All optional. Skip what you don't know — we default to evidence-based targets."
            }
        }

        var iconName: String {
            switch self {
            case .caffeine:         return "cup.and.saucer.fill"
            case .dietary:          return "leaf.fill"
            case .giSensitivities:  return "stethoscope"
            case .formats:          return "square.stack.fill"
            case .advanced:         return "slider.horizontal.3"
            }
        }
    }

    /// The sequence of steps the athlete will see, derived from race
    /// distance. Order matters: caffeine first (simple), dietary next
    /// (familiar), GI/formats when applicable, advanced last (optional).
    private var steps: [Step] {
        var s: [Step] = [.caffeine, .dietary]
        if needsExtendedQuestions {
            s.append(.giSensitivities)
            s.append(.formats)
        }
        if needsAdvancedQuestions {
            s.append(.advanced)
        }
        return s
    }

    private var currentStep: Step { steps[stepIndex] }
    private var isLastStep: Bool { stepIndex == steps.count - 1 }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        stepHeader
                        stepContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .background(Theme.Gradients.futuristicBackground(colorScheme: colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(raceName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("\(Int(raceDistanceKm)) km · \(stepIndex + 1) of \(steps.count)")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.tertiaryLabel)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { navigationBar }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.tertiaryLabel.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(
                        colors: [NutritionOnboardingTheme.tint, NutritionOnboardingTheme.tint.opacity(0.75)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * CGFloat(stepIndex + 1) / CGFloat(steps.count))
            }
        }
        .frame(height: 3)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Step header (icon + title + subtitle)

    private var stepHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: currentStep.iconName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(NutritionOnboardingTheme.gradient))
                .shadow(color: NutritionOnboardingTheme.tint.opacity(0.3), radius: 8, y: 4)

            Text(currentStep.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(currentStep.subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.md)
        .id(currentStep)
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch currentStep {
            case .caffeine:        caffeineStep
            case .dietary:         dietaryStep
            case .giSensitivities: giStep
            case .formats:         formatsStep
            case .advanced:        advancedStep
            }
        }
        .animation(.easeInOut(duration: 0.2), value: stepIndex)
    }

    // MARK: - Caffeine

    private var caffeineStep: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(CaffeineSensitivity.allCases, id: \.self) { sensitivity in
                SelectableCard(
                    title: sensitivity.displayName,
                    subtitle: caffeineSubtitle(sensitivity),
                    icon: caffeineIcon(sensitivity),
                    isSelected: preferences.caffeineSensitivity == sensitivity
                ) {
                    preferences.caffeineSensitivity = sensitivity
                    preferences.avoidCaffeine = sensitivity == .none
                }
            }
        }
    }

    private func caffeineSubtitle(_ s: CaffeineSensitivity) -> String {
        switch s {
        case .none:      return "No coffee, tea, or caffeinated drinks"
        case .low:       return "Occasional — not a daily drinker"
        case .moderate:  return "1-2 coffees or equivalent per day"
        case .high:      return "3+ coffees or strong daily habit"
        }
    }

    private func caffeineIcon(_ s: CaffeineSensitivity) -> String {
        switch s {
        case .none:      return "cup.and.saucer"
        case .low, .moderate, .high:
            return "cup.and.saucer.fill"
        }
    }

    // MARK: - Dietary

    private var dietaryStep: some View {
        VStack(spacing: Theme.Spacing.sm) {
            noneOrChipsGrid(
                items: DietaryRestriction.allCases,
                title: { $0.displayName },
                isSelected: { preferences.dietaryRestrictions.contains($0) },
                onToggle: { restriction in
                    if preferences.dietaryRestrictions.contains(restriction) {
                        preferences.dietaryRestrictions.remove(restriction)
                    } else {
                        preferences.dietaryRestrictions.insert(restriction)
                    }
                },
                isEmpty: preferences.dietaryRestrictions.isEmpty,
                onClear: { preferences.dietaryRestrictions.removeAll() }
            )
        }
    }

    // MARK: - GI sensitivities

    private var giStep: some View {
        VStack(spacing: Theme.Spacing.sm) {
            noneOrChipsGrid(
                items: GISensitivity.allCases,
                title: { $0.displayName },
                isSelected: { preferences.giSensitivities.contains($0) },
                onToggle: { sensitivity in
                    if preferences.giSensitivities.contains(sensitivity) {
                        preferences.giSensitivities.remove(sensitivity)
                    } else {
                        preferences.giSensitivities.insert(sensitivity)
                    }
                },
                isEmpty: preferences.giSensitivities.isEmpty,
                onClear: { preferences.giSensitivities.removeAll() }
            )
        }
    }

    // MARK: - Formats

    private var formatsStep: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ChipsGrid(
                items: ProductType.allCases,
                title: { formatTitle($0) },
                icon: { formatIcon($0) },
                isSelected: { preferences.preferredFormats.contains($0) },
                onToggle: { format in
                    if preferences.preferredFormats.contains(format) {
                        preferences.preferredFormats.remove(format)
                    } else {
                        preferences.preferredFormats.insert(format)
                    }
                }
            )
            Text("Tap everything you're happy to use. Leave empty for no preference.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.Spacing.xs)
        }
    }

    private func formatTitle(_ type: ProductType) -> String {
        switch type {
        case .gel:      "Gels"
        case .chew:     "Chews"
        case .drink:    "Drinks"
        case .bar:      "Bars"
        case .realFood: "Real food"
        case .salt:     "Salt caps"
        }
    }

    private func formatIcon(_ type: ProductType) -> String {
        switch type {
        case .gel:      "drop.fill"
        case .chew:     "circle.grid.3x3.fill"
        case .drink:    "waterbottle.fill"
        case .bar:      "rectangle.fill"
        case .realFood: "leaf.fill"
        case .salt:     "pills.fill"
        }
    }

    // MARK: - Advanced

    private var advancedStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Toggle(isOn: $preferences.sweatProfile.heavySaltySweater) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Heavy salty sweater").font(.subheadline.weight(.semibold))
                    Text("White salt marks on dark shirts, stinging eyes, crystals on skin")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }
            }
            .tint(NutritionOnboardingTheme.tint)
            .padding(Theme.Spacing.md)
            .background(tintedCard)

            advancedNumericField(
                label: "Max carbs/hour you've tolerated",
                placeholder: "e.g. 80",
                unit: "g/hr",
                text: $carbsToleranceText,
                hint: "From training. Leave blank if you haven't gut-trained."
            )
            .onChange(of: carbsToleranceText) { _, new in
                preferences.carbsPerHourTolerance = Int(new)
            }

            advancedNumericField(
                label: "Sweat rate",
                placeholder: "e.g. 900",
                unit: "ml/hr",
                text: $sweatRateText,
                hint: nil
            )
            .onChange(of: sweatRateText) { _, new in
                preferences.sweatProfile.sweatRateMlPerHour = Int(new)
            }

            advancedNumericField(
                label: "Sweat sodium",
                placeholder: "e.g. 1000",
                unit: "mg/L",
                text: $sweatSodiumText,
                hint: "From a lab test. Skip if untested."
            )
            .onChange(of: sweatSodiumText) { _, new in
                preferences.sweatProfile.sweatSodiumMgPerL = Int(new)
            }

            Text("All fields optional. Skip what you don't know — we'll use evidence-based defaults.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func advancedNumericField(
        label: String,
        placeholder: String,
        unit: String,
        text: Binding<String>,
        hint: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.weight(.semibold))
            HStack {
                TextField(placeholder, text: text)
                    .keyboardType(.numberPad)
                    .font(.title3.monospacedDigit())
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
        }
        .padding(Theme.Spacing.md)
        .background(tintedCard)
    }

    private var tintedCard: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(NutritionOnboardingTheme.tint.opacity(0.14), lineWidth: 0.75)
            )
    }

    // MARK: - Navigation bar

    private var navigationBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if stepIndex > 0 {
                Button {
                    withAnimation { stepIndex -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm + 2)
                }
                .buttonStyle(.bordered)
                .tint(Theme.Colors.secondaryLabel)
            }

            Button {
                if isLastStep {
                    submit()
                } else {
                    withAnimation { stepIndex += 1 }
                }
            } label: {
                Label(
                    isLastStep ? "Generate my plan" : "Continue",
                    systemImage: isLastStep ? "checkmark.circle.fill" : "chevron.right"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .foregroundStyle(.white)
                .background(NutritionOnboardingTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .shadow(color: NutritionOnboardingTheme.tint.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(isLastStep ? "nutrition.onboarding.generate" : "nutrition.onboarding.continue")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.regularMaterial)
    }

    private func submit() {
        var final = preferences
        final.onboardingCompleted = true
        onGenerate(final)
        dismiss()
    }

    // MARK: - None-or-chips grid helper

    /// Adds a "None" chip at the start that clears the whole selection.
    /// Keeps "nothing to avoid" as a one-tap state rather than leaving
    /// the athlete to figure out that empty = none.
    @ViewBuilder
    private func noneOrChipsGrid<Item: Hashable>(
        items: [Item],
        title: @escaping (Item) -> String,
        isSelected: @escaping (Item) -> Bool,
        onToggle: @escaping (Item) -> Void,
        isEmpty: Bool,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Button {
                    onClear()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isEmpty ? "checkmark.circle.fill" : "circle")
                            .font(.caption.weight(.bold))
                        Text("None — nothing to flag")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(isEmpty ? .white : Theme.Colors.label)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm + 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(isEmpty
                                  ? AnyShapeStyle(NutritionOnboardingTheme.gradient)
                                  : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.7)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(NutritionOnboardingTheme.tint.opacity(isEmpty ? 0.0 : 0.14), lineWidth: 0.75)
                    )
                }
                .buttonStyle(.plain)
            }
            ChipsGrid(
                items: items,
                title: title,
                icon: { _ in nil },
                isSelected: isSelected,
                onToggle: onToggle
            )
        }
    }
}

// MARK: - Selectable card

/// Large full-width card with icon + title + optional subtitle. Matches
/// the main onboarding aesthetic (ExperienceLevelCard-style). Replaces
/// the tiny radio rows that made the old sheet feel like a DMV form.
private struct SelectableCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : NutritionOnboardingTheme.tint)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(
                            isSelected
                                ? AnyShapeStyle(NutritionOnboardingTheme.gradient)
                                : AnyShapeStyle(NutritionOnboardingTheme.tint.opacity(0.14))
                        )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(NutritionOnboardingTheme.tint)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(
                        isSelected ? NutritionOnboardingTheme.tint : Theme.Colors.tertiaryLabel.opacity(0.14),
                        lineWidth: isSelected ? 1.5 : 0.75
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chips grid

private struct ChipsGrid<Item: Hashable>: View {
    let items: [Item]
    let title: (Item) -> String
    let icon: (Item) -> String?
    let isSelected: (Item) -> Bool
    let onToggle: (Item) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FlowLayout(spacing: Theme.Spacing.xs + 2) {
            ForEach(items, id: \.self) { item in
                let selected = isSelected(item)
                Button {
                    onToggle(item)
                } label: {
                    HStack(spacing: 6) {
                        if let iconName = icon(item) {
                            Image(systemName: iconName)
                                .font(.caption2.weight(.bold))
                        }
                        Text(title(item))
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, Theme.Spacing.sm + 2)
                    .padding(.vertical, Theme.Spacing.xs + 2)
                    .background(
                        Capsule().fill(
                            selected
                                ? AnyShapeStyle(NutritionOnboardingTheme.gradient)
                                : AnyShapeStyle(colorScheme == .dark
                                                ? Color.white.opacity(0.08)
                                                : Color.white.opacity(0.7))
                        )
                    )
                    .overlay(
                        Capsule().stroke(
                            selected ? Color.clear : Theme.Colors.tertiaryLabel.opacity(0.14),
                            lineWidth: 0.75
                        )
                    )
                    .foregroundStyle(selected ? .white : Theme.Colors.label)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Flow layout

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                currentRowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? currentRowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
