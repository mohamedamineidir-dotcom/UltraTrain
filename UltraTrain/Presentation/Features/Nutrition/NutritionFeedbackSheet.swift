import SwiftUI

/// Post-long-run nutrition feedback sheet. Stepped flow that mirrors the
/// nutrition onboarding pattern — one focused question at a time, green
/// palette, big tappable cards — so logging feels like a conversation
/// rather than a form. Feeds the Phase 4 refinement loop with NIQEC GI
/// symptom ratings, energy/bonk state, actual carbs consumed, and per-
/// product tolerance.
struct NutritionFeedbackSheet: View {

    let sessionId: UUID
    let sessionLabel: String
    let plannedCarbsPerHour: Int
    let durationMinutes: Int
    /// Products the athlete can mark as tolerated / intolerant — typically
    /// the distinct products scheduled for the race plan.
    let availableProducts: [NutritionProduct]
    let existingFeedback: NutritionSessionFeedback?
    let onSave: (NutritionSessionFeedback) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var stepIndex: Int = 0
    @State private var actualCarbsText: String = ""
    @State private var nausea: Double = 0
    @State private var bloating: Double = 0
    @State private var cramping: Double = 0
    @State private var urgency: Double = 0
    @State private var energyLevel: Double = 7
    @State private var bonked: Bool = false
    @State private var tolerated: Set<UUID> = []
    @State private var intolerant: Set<UUID> = []
    @State private var notes: String = ""

    init(
        sessionId: UUID,
        sessionLabel: String,
        plannedCarbsPerHour: Int,
        durationMinutes: Int,
        availableProducts: [NutritionProduct],
        existingFeedback: NutritionSessionFeedback? = nil,
        onSave: @escaping (NutritionSessionFeedback) -> Void
    ) {
        self.sessionId = sessionId
        self.sessionLabel = sessionLabel
        self.plannedCarbsPerHour = plannedCarbsPerHour
        self.durationMinutes = durationMinutes
        self.availableProducts = availableProducts
        self.existingFeedback = existingFeedback
        self.onSave = onSave
    }

    // MARK: - Steps

    fileprivate enum Step: Int, CaseIterable {
        case intake
        case giSymptoms
        case energy
        case products
        case notes

        var title: String {
            switch self {
            case .intake:     return "What did you actually take in?"
            case .giSymptoms: return "Any stomach trouble?"
            case .energy:     return "How did your energy hold up?"
            case .products:   return "Which products worked?"
            case .notes:      return "Anything to flag?"
            }
        }

        var subtitle: String {
            switch self {
            case .intake:
                return "Roughly how many grams of carbs per hour did you manage?"
            case .giSymptoms:
                return "0 means none, 10 means severe. Slide each axis to where you landed."
            case .energy:
                return "Finish strong, or did the wheels come off?"
            case .products:
                return "Tag what sat well and what didn't. Skip anything you didn't try."
            case .notes:
                return "A short note helps us tune next week's plan. Optional."
            }
        }

        var iconName: String {
            switch self {
            case .intake:     return "chart.line.uptrend.xyaxis"
            case .giSymptoms: return "stethoscope"
            case .energy:     return "bolt.fill"
            case .products:   return "square.stack.fill"
            case .notes:      return "note.text"
            }
        }
    }

    private var steps: [Step] {
        var s: [Step] = [.intake, .giSymptoms, .energy]
        if !distinctProducts.isEmpty { s.append(.products) }
        s.append(.notes)
        return s
    }

    private var currentStep: Step { steps[stepIndex] }
    private var isLastStep: Bool { stepIndex == steps.count - 1 }

    private var distinctProducts: [NutritionProduct] {
        Array(
            Dictionary(grouping: availableProducts) { $0.id }
                .compactMapValues(\.first)
                .values
        ).sorted { $0.name < $1.name }
    }

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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(sessionLabel)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("Planned \(plannedCarbsPerHour) g/hr · \(durationMinutes) min · \(stepIndex + 1) of \(steps.count)")
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.tertiaryLabel)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { navigationBar }
        }
        .onAppear(perform: seedFromExisting)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.tertiaryLabel.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(
                        colors: [NutritionPalette.tint, NutritionPalette.tint.opacity(0.75)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * CGFloat(stepIndex + 1) / CGFloat(steps.count))
            }
        }
        .frame(height: 3)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Step header

    private var stepHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: currentStep.iconName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(NutritionPalette.gradient))
                .shadow(color: NutritionPalette.tint.opacity(0.3), radius: 8, y: 4)

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
            case .intake:     intakeStep
            case .giSymptoms: giStep
            case .energy:     energyStep
            case .products:   productsStep
            case .notes:      notesStep
            }
        }
        .animation(.easeInOut(duration: 0.2), value: stepIndex)
    }

    // MARK: - Intake step

    private var intakeStep: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Preset chips — gut-training typical range
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(intakePresets, id: \.self) { preset in
                    intakePresetCard(preset)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exact amount")
                        .font(.subheadline.weight(.semibold))
                    HStack {
                        TextField("e.g. 65", text: $actualCarbsText)
                            .keyboardType(.numberPad)
                            .font(.title3.monospacedDigit())
                        Text("g/hr")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(tintedCard)
        }
    }

    private var intakePresets: [Int] { [40, 60, 80, 100] }

    private func intakePresetCard(_ grams: Int) -> some View {
        let selected = Int(actualCarbsText) == grams
        let planned = plannedCarbsPerHour
        let label: String = {
            if grams < planned - 15 { return "Well under plan" }
            if grams < planned - 5  { return "A bit under plan" }
            if grams <= planned + 5 { return "On plan" }
            return "Above plan"
        }()
        return Button {
            actualCarbsText = "\(grams)"
        } label: {
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                Text("\(grams)")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(selected ? .white : NutritionPalette.tint)
                    .frame(width: 56, height: 38)
                    .background(
                        Capsule().fill(
                            selected
                                ? AnyShapeStyle(NutritionPalette.gradient)
                                : AnyShapeStyle(NutritionPalette.tint.opacity(0.14))
                        )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(grams) g/hr")
                        .font(.subheadline.weight(.semibold))
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(NutritionPalette.tint)
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
                        selected ? NutritionPalette.tint : Theme.Colors.tertiaryLabel.opacity(0.14),
                        lineWidth: selected ? 1.5 : 0.75
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - GI step

    private var giStep: some View {
        VStack(spacing: Theme.Spacing.sm) {
            symptomCard(title: "Nausea",            value: $nausea)
            symptomCard(title: "Bloating/fullness", value: $bloating)
            symptomCard(title: "Cramping",          value: $cramping)
            symptomCard(title: "Urgency",           value: $urgency)
        }
    }

    private func symptomCard(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(symptomLabel(value.wrappedValue))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(symptomTint(value.wrappedValue))
                    .padding(.horizontal, Theme.Spacing.xs + 2)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(symptomTint(value.wrappedValue).opacity(0.15))
                    )
                Text("\(Int(value.wrappedValue))")
                    .font(.subheadline.bold().monospacedDigit())
                    .frame(width: 24, alignment: .trailing)
            }
            Slider(value: value, in: 0...10, step: 1)
                .tint(symptomTint(value.wrappedValue))
        }
        .padding(Theme.Spacing.md)
        .background(tintedCard)
    }

    private func symptomLabel(_ value: Double) -> String {
        if value == 0 { return "none" }
        if value <= 3 { return "mild" }
        if value <= 6 { return "moderate" }
        return "severe"
    }

    private func symptomTint(_ value: Double) -> Color {
        if value == 0 { return NutritionPalette.tint }
        if value <= 3 { return NutritionPalette.tint }
        if value <= 6 { return .orange }
        return .red
    }

    // MARK: - Energy step

    private var energyStep: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Energy at finish")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(energyLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(energyTint)
                        .padding(.horizontal, Theme.Spacing.xs + 2)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(energyTint.opacity(0.15)))
                    Text("\(Int(energyLevel))")
                        .font(.subheadline.bold().monospacedDigit())
                        .frame(width: 24, alignment: .trailing)
                }
                Slider(value: $energyLevel, in: 0...10, step: 1)
                    .tint(energyTint)
                HStack {
                    Text("Bonked")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                    Spacer()
                    Text("Fresh")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }
            }
            .padding(Theme.Spacing.md)
            .background(tintedCard)

            Button {
                bonked.toggle()
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: bonked ? "exclamationmark.triangle.fill" : "checkmark.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(bonked ? .white : Theme.Colors.tertiaryLabel)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle().fill(
                                bonked
                                    ? AnyShapeStyle(
                                        LinearGradient(colors: [.orange, .red],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing))
                                    : AnyShapeStyle(Color.gray.opacity(0.15))
                            )
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I bonked / hit the wall")
                            .font(.subheadline.weight(.semibold))
                        Text(bonked ? "We'll factor this into the refinement."
                                    : "Tap if you blew up before the finish.")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                    if bonked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
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
                            bonked ? Color.orange : Theme.Colors.tertiaryLabel.opacity(0.14),
                            lineWidth: bonked ? 1.5 : 0.75
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var energyLabel: String {
        switch Int(energyLevel) {
        case 0...2: return "bonked"
        case 3...4: return "drained"
        case 5...6: return "ok"
        case 7...8: return "strong"
        default:    return "fresh"
        }
    }

    private var energyTint: Color {
        switch Int(energyLevel) {
        case 0...3: return .red
        case 4...5: return .orange
        default:    return NutritionPalette.tint
        }
    }

    // MARK: - Products step

    private var productsStep: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(distinctProducts) { product in
                productCard(product)
            }
            Text("Tap green for worked, red for didn't. Leave grey if you didn't try it.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.xs)
        }
    }

    private func productCard(_ product: NutritionProduct) -> some View {
        let isTolerated = tolerated.contains(product.id)
        let isIntolerant = intolerant.contains(product.id)
        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: product.type.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(product.type.color)
                .frame(width: 38, height: 38)
                .background(Circle().fill(product.type.color.opacity(0.18)))

            VStack(alignment: .leading, spacing: 2) {
                if let brand = product.brand, !brand.isEmpty {
                    Text(brand.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(product.type.color)
                        .tracking(0.5)
                }
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: Theme.Spacing.sm) {
                verdictButton(
                    icon: "checkmark",
                    tint: NutritionPalette.tint,
                    isOn: isTolerated
                ) {
                    if isTolerated {
                        tolerated.remove(product.id)
                    } else {
                        tolerated.insert(product.id)
                        intolerant.remove(product.id)
                    }
                }
                verdictButton(
                    icon: "xmark",
                    tint: .red,
                    isOn: isIntolerant
                ) {
                    if isIntolerant {
                        intolerant.remove(product.id)
                    } else {
                        intolerant.insert(product.id)
                        tolerated.remove(product.id)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(tintedCard)
    }

    private func verdictButton(
        icon: String,
        tint: Color,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isOn ? .white : tint)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(isOn ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)))
                )
                .overlay(
                    Circle().stroke(tint.opacity(isOn ? 0 : 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes step

    private var notesStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Your notes")
                    .font(.subheadline.weight(.semibold))
                TextField("e.g. gel at 1h was too sweet", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
                    .font(.subheadline)
            }
            .padding(Theme.Spacing.md)
            .background(tintedCard)

            summarySummary
        }
    }

    private var summarySummary: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Label("Quick summary", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NutritionPalette.tint)
            summaryRow(
                label: "Actual intake",
                value: actualCarbsText.isEmpty ? "—" : "\(actualCarbsText) g/hr"
            )
            summaryRow(
                label: "Max GI symptom",
                value: maxSymptomText
            )
            summaryRow(
                label: "Energy at finish",
                value: "\(Int(energyLevel))/10\(bonked ? " · bonked" : "")"
            )
            if !tolerated.isEmpty || !intolerant.isEmpty {
                summaryRow(
                    label: "Products",
                    value: "\(tolerated.count) worked · \(intolerant.count) didn't"
                )
            }
        }
        .padding(Theme.Spacing.md)
        .background(tintedCard)
    }

    private var maxSymptomText: String {
        let maxValue = Int(max(max(nausea, bloating), max(cramping, urgency)))
        return maxValue == 0 ? "none" : "\(maxValue)/10"
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.Colors.label)
        }
    }

    // MARK: - Shared tinted card background

    private var tintedCard: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(NutritionPalette.tint.opacity(0.14), lineWidth: 0.75)
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
                    saveFeedback()
                } else {
                    withAnimation { stepIndex += 1 }
                }
            } label: {
                Label(
                    isLastStep ? "Save feedback" : "Continue",
                    systemImage: isLastStep ? "checkmark.circle.fill" : "chevron.right"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .foregroundStyle(.white)
                .background(NutritionPalette.gradient)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .shadow(color: NutritionPalette.tint.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(isLastStep ? "nutrition.feedback.save" : "nutrition.feedback.continue")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.regularMaterial)
    }

    // MARK: - Persistence

    private func seedFromExisting() {
        guard let existing = existingFeedback else { return }
        actualCarbsText = "\(existing.actualCarbsConsumed)"
        nausea = Double(existing.nausea)
        bloating = Double(existing.bloating)
        cramping = Double(existing.cramping)
        urgency = Double(existing.urgency)
        energyLevel = Double(existing.energyLevel)
        bonked = existing.bonked
        tolerated = existing.toleratedProductIds
        intolerant = existing.intolerantProductIds
        notes = existing.notes ?? ""
    }

    private func saveFeedback() {
        let feedback = NutritionSessionFeedback(
            id: existingFeedback?.id ?? UUID(),
            sessionId: sessionId,
            plannedCarbsPerHour: plannedCarbsPerHour,
            actualCarbsConsumed: Int(actualCarbsText) ?? 0,
            durationMinutes: durationMinutes,
            nausea: Int(nausea),
            bloating: Int(bloating),
            cramping: Int(cramping),
            urgency: Int(urgency),
            energyLevel: Int(energyLevel),
            bonked: bonked,
            toleratedProductIds: tolerated,
            intolerantProductIds: intolerant,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            createdAt: existingFeedback?.createdAt ?? Date()
        )
        onSave(feedback)
        dismiss()
    }
}
