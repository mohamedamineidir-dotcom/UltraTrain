import SwiftUI

/// Pre-plan nutrition onboarding sheet. Presented before "Generate Plan" on
/// the Race Day tab to capture the athlete's goals, caffeine habits, GI
/// sensitivities, format preferences, carbs-per-hour tolerance, and sweat
/// profile. Sections are gated by race distance so a 5K athlete sees only
/// the essentials, while a marathon or ultra athlete is asked the full set.
struct NutritionOnboardingSheet: View {

    let raceName: String
    let raceDistanceKm: Double
    let initialPreferences: NutritionPreferences
    let onGenerate: (NutritionPreferences) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var preferences: NutritionPreferences
    @State private var caffeineHabitText: String = ""
    @State private var carbsToleranceText: String = ""
    @State private var sweatRateText: String = ""
    @State private var sweatSodiumText: String = ""
    @State private var showAdvanced: Bool = false

    init(
        raceName: String,
        raceDistanceKm: Double,
        initialPreferences: NutritionPreferences,
        onGenerate: @escaping (NutritionPreferences) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.raceName = raceName
        self.raceDistanceKm = raceDistanceKm
        self.initialPreferences = initialPreferences
        self.onGenerate = onGenerate
        self.onCancel = onCancel
        _preferences = State(initialValue: initialPreferences)
    }

    // MARK: - Gating

    /// Half marathon and longer — ask about GI sensitivities and format prefs.
    private var needsExtendedQuestions: Bool { raceDistanceKm >= 18 }
    /// Marathon, trail, and ultra — ask about carbs/hr tolerance + sweat profile.
    private var needsAdvancedQuestions: Bool { raceDistanceKm >= 35 }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    goalSection
                    caffeineSection
                    dietarySection

                    if needsExtendedQuestions {
                        giSensitivitySection
                        formatPreferenceSection
                    }

                    if needsAdvancedQuestions {
                        advancedSection
                    }

                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding()
            }
            .navigationTitle("Personalize your plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                generateButton
            }
        }
        .interactiveDismissDisabled(false)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(raceName)
                .font(.title3.bold())
            Text("\(Int(raceDistanceKm)) km race")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Answer a few questions so your race-day plan matches your physiology, preferences, and goals. You can skip anything you're unsure about — we'll use safe defaults.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, Theme.Spacing.xs)
        }
    }

    // MARK: - Goal

    private var goalSection: some View {
        Section {
            sectionHeader("Your goal", systemImage: "flag.checkered")
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(NutritionGoal.allCases, id: \.self) { goal in
                    OnboardingRadioRow(
                        title: goal.displayName,
                        subtitle: goalSubtitle(goal),
                        isSelected: preferences.nutritionGoal == goal
                    ) {
                        preferences.nutritionGoal = goal
                    }
                }
            }
        }
    }

    private func goalSubtitle(_ goal: NutritionGoal) -> String {
        switch goal {
        case .finishComfortably: "Conservative fueling, prioritize GI safety"
        case .targetTime:        "Standard evidence-based targets"
        case .competitive:       "Aggressive carbs (requires gut training)"
        }
    }

    // MARK: - Caffeine

    private var caffeineSection: some View {
        Section {
            sectionHeader("Caffeine", systemImage: "cup.and.saucer.fill")
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(CaffeineSensitivity.allCases, id: \.self) { sensitivity in
                    OnboardingRadioRow(
                        title: sensitivity.displayName,
                        subtitle: nil,
                        isSelected: preferences.caffeineSensitivity == sensitivity
                    ) {
                        preferences.caffeineSensitivity = sensitivity
                        preferences.avoidCaffeine = sensitivity == .none
                    }
                }
            }

            if preferences.caffeineSensitivity != .none {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Daily intake (mg, optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. 200", text: $caffeineHabitText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: caffeineHabitText) { _, new in
                            preferences.caffeineHabitMgPerDay = Int(new)
                        }
                    Text("One coffee ≈ 95 mg, one espresso ≈ 63 mg. Used to calibrate race-day dose.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
    }

    // MARK: - Dietary restrictions

    private var dietarySection: some View {
        Section {
            sectionHeader("Dietary restrictions", systemImage: "leaf.fill")
            Text("Any we should respect when picking products?")
                .font(.caption)
                .foregroundStyle(.secondary)
            ChipsGrid(
                items: DietaryRestriction.allCases,
                title: { $0.displayName },
                isSelected: { preferences.dietaryRestrictions.contains($0) },
                onToggle: { restriction in
                    if preferences.dietaryRestrictions.contains(restriction) {
                        preferences.dietaryRestrictions.remove(restriction)
                    } else {
                        preferences.dietaryRestrictions.insert(restriction)
                    }
                }
            )
        }
    }

    // MARK: - GI sensitivities (extended)

    private var giSensitivitySection: some View {
        Section {
            sectionHeader("Known GI sensitivities", systemImage: "exclamationmark.triangle.fill")
            Text("Things that have caused stomach trouble in past races or long runs.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ChipsGrid(
                items: GISensitivity.allCases,
                title: { $0.displayName },
                isSelected: { preferences.giSensitivities.contains($0) },
                onToggle: { sensitivity in
                    if preferences.giSensitivities.contains(sensitivity) {
                        preferences.giSensitivities.remove(sensitivity)
                    } else {
                        preferences.giSensitivities.insert(sensitivity)
                    }
                }
            )
        }
    }

    // MARK: - Format preferences (extended)

    private var formatPreferenceSection: some View {
        Section {
            sectionHeader("Preferred formats", systemImage: "square.stack.fill")
            Text("Select formats you like. Leave empty for no preference.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ChipsGrid(
                items: ProductType.allCases,
                title: { formatTitle($0) },
                isSelected: { preferences.preferredFormats.contains($0) },
                onToggle: { format in
                    if preferences.preferredFormats.contains(format) {
                        preferences.preferredFormats.remove(format)
                    } else {
                        preferences.preferredFormats.insert(format)
                    }
                }
            )
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

    // MARK: - Advanced (marathon+)

    private var advancedSection: some View {
        DisclosureGroup(isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Carbs tolerance
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Max carbs/hour you've tolerated in training")
                        .font(.subheadline.weight(.medium))
                    TextField("e.g. 80 (g/hr)", text: $carbsToleranceText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: carbsToleranceText) { _, new in
                            preferences.carbsPerHourTolerance = Int(new)
                        }
                    Text("Leave blank if you haven't gut-trained yet. The generator will prescribe an evidence-based target based on your race duration.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // Sweat profile
                Toggle(isOn: $preferences.sweatProfile.heavySaltySweater) {
                    VStack(alignment: .leading) {
                        Text("Heavy salty sweater").font(.subheadline.weight(.medium))
                        Text("White salt marks on dark shirts, stinging eyes, crystals on skin")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Measured sweat rate (ml/hr, optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. 900", text: $sweatRateText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: sweatRateText) { _, new in
                            preferences.sweatProfile.sweatRateMlPerHour = Int(new)
                        }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Measured sweat sodium (mg/L, optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. 1000", text: $sweatSodiumText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: sweatSodiumText) { _, new in
                            preferences.sweatProfile.sweatSodiumMgPerL = Int(new)
                        }
                    Text("From a lab test (e.g. Precision Fuel & Hydration). If you haven't tested, skip.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, Theme.Spacing.sm)
        } label: {
            sectionHeader("Advanced (optional)", systemImage: "slider.horizontal.3")
        }
    }

    // MARK: - Generate button

    private var generateButton: some View {
        VStack {
            Button {
                var final = preferences
                final.onboardingCompleted = true
                onGenerate(final)
                dismiss()
            } label: {
                Text("Generate my plan")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("nutrition.onboarding.generate")
        }
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
    }
}

// MARK: - Radio row

private struct OnboardingRadioRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Theme.Colors.accentColor : Theme.Colors.secondaryLabel)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.medium))
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Theme.Colors.accentColor.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Theme.Colors.accentColor.opacity(0.4) : Theme.Colors.secondaryLabel.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chips grid

private struct ChipsGrid<Item: Hashable>: View {
    let items: [Item]
    let title: (Item) -> String
    let isSelected: (Item) -> Bool
    let onToggle: (Item) -> Void

    var body: some View {
        FlowLayout(spacing: Theme.Spacing.xs) {
            ForEach(items, id: \.self) { item in
                let selected = isSelected(item)
                Button {
                    onToggle(item)
                } label: {
                    Text(title(item))
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            Capsule().fill(selected ? Theme.Colors.accentColor.opacity(0.15) : Color.gray.opacity(0.12))
                        )
                        .overlay(
                            Capsule().stroke(selected ? Theme.Colors.accentColor : Color.clear, lineWidth: 1)
                        )
                        .foregroundStyle(selected ? Theme.Colors.accentColor : Theme.Colors.label)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Flow layout (for wrapping chips)

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
