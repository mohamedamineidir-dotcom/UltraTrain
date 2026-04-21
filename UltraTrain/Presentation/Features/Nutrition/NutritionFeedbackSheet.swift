import SwiftUI

/// Post-long-run nutrition feedback form. Captures NIQEC-style GI symptoms,
/// energy / bonk state, actual carbs consumed, and per-product tolerance —
/// everything the Phase 4 refinement use case needs to adjust the race plan.
struct NutritionFeedbackSheet: View {

    let sessionId: UUID
    let sessionLabel: String
    let plannedCarbsPerHour: Int
    let durationMinutes: Int
    /// Products the athlete can mark as tolerated / intolerant — typically the
    /// distinct products scheduled for the race plan.
    let availableProducts: [NutritionProduct]
    let existingFeedback: NutritionSessionFeedback?
    let onSave: (NutritionSessionFeedback) -> Void

    @Environment(\.dismiss) private var dismiss

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    intakeSection
                    giSymptomSection
                    energySection
                    productsSection
                    notesSection
                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding()
            }
            .navigationTitle("How did it go?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { saveButton }
        }
        .onAppear(perform: seedFromExisting)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sessionLabel).font(.title3.bold())
            Text("Planned: \(plannedCarbsPerHour) g/hr · \(durationMinutes) min")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Your feedback tunes the race-day plan to what your gut actually tolerates.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, Theme.Spacing.xs)
        }
    }

    private var intakeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionHeader("Actual intake", systemImage: "chart.line.uptrend.xyaxis")
            Text("Roughly how many grams of carbs per hour did you actually consume?")
                .font(.caption).foregroundStyle(.secondary)
            TextField("e.g. 65", text: $actualCarbsText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var giSymptomSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionHeader("GI symptoms", systemImage: "stethoscope")
            Text("0 = none, 10 = severe. Rate each axis.")
                .font(.caption).foregroundStyle(.secondary)
            symptomSlider(title: "Nausea", value: $nausea)
            symptomSlider(title: "Bloating / fullness", value: $bloating)
            symptomSlider(title: "Cramping", value: $cramping)
            symptomSlider(title: "Urgency (bathroom)", value: $urgency)
        }
    }

    private func symptomSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(Int(value.wrappedValue))").font(.caption.monospacedDigit().weight(.semibold))
            }
            Slider(value: value, in: 0...10, step: 1)
                .tint(sliderTint(value.wrappedValue))
        }
    }

    private func sliderTint(_ value: Double) -> Color {
        if value <= 3 { return .green }
        if value <= 6 { return .orange }
        return .red
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionHeader("Energy & performance", systemImage: "bolt.fill")
            HStack {
                Text("Energy at finish").font(.subheadline)
                Spacer()
                Text("\(Int(energyLevel))").font(.caption.monospacedDigit().weight(.semibold))
            }
            Slider(value: $energyLevel, in: 0...10, step: 1)
                .tint(.accentColor)
            Toggle("I bonked / hit the wall", isOn: $bonked)
                .font(.subheadline)
        }
    }

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionHeader("Products", systemImage: "square.stack.fill")
            Text("Tap to mark each product as Tolerated or Intolerant. Skip if you didn't try it.")
                .font(.caption).foregroundStyle(.secondary)

            let distinctProducts = Array(
                Dictionary(grouping: availableProducts) { $0.id }
                    .compactMapValues(\.first)
                    .values
            ).sorted { $0.name < $1.name }

            if distinctProducts.isEmpty {
                Text("No products in the current plan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                ForEach(distinctProducts) { product in
                    productRow(product)
                }
            }
        }
    }

    private func productRow(_ product: NutritionProduct) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: product.type.icon)
                .foregroundStyle(product.type.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 0) {
                if let brand = product.brand {
                    Text(brand.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(product.type.color)
                }
                Text(product.name).font(.subheadline.weight(.medium))
            }
            Spacer()
            productToggleButton(
                systemImage: "checkmark.circle.fill",
                tint: .green,
                isOn: tolerated.contains(product.id)
            ) {
                if tolerated.contains(product.id) {
                    tolerated.remove(product.id)
                } else {
                    tolerated.insert(product.id)
                    intolerant.remove(product.id)
                }
            }
            productToggleButton(
                systemImage: "xmark.circle.fill",
                tint: .red,
                isOn: intolerant.contains(product.id)
            ) {
                if intolerant.contains(product.id) {
                    intolerant.remove(product.id)
                } else {
                    intolerant.insert(product.id)
                    tolerated.remove(product.id)
                }
            }
        }
        .padding(Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    private func productToggleButton(
        systemImage: String,
        tint: Color,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(isOn ? tint : Theme.Colors.tertiaryLabel)
        }
        .buttonStyle(.plain)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionHeader("Notes (optional)", systemImage: "note.text")
            TextField("Anything else? e.g. 'gel at 1h was too sweet'", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var saveButton: some View {
        VStack {
            Button {
                saveFeedback()
            } label: {
                Text("Save feedback")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("nutrition.feedback.save")
        }
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage).font(.headline)
    }

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
