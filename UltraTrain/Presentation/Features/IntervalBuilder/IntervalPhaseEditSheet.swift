import SwiftUI

struct IntervalPhaseEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State var phaseType: IntervalPhaseType = .work
    @State var triggerType: TriggerType = .duration
    @State var durationMinutes: Int = 3
    @State var durationSeconds: Int = 0
    @State var distanceKm: Double = 1.0
    @State var intensity: Intensity = .hard
    @State var repeatCount: Int = 1

    var existingPhase: IntervalPhase?
    let onSave: (IntervalPhase) -> Void

    enum TriggerType: String, CaseIterable {
        case duration = "Time"
        case distance = "Distance"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Phase Type") {
                    Picker("Type", selection: $phaseType) {
                        ForEach(IntervalPhaseType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Trigger") {
                    Picker("Trigger", selection: $triggerType) {
                        ForEach(TriggerType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if triggerType == .duration {
                        Stepper("Minutes: \(durationMinutes)", value: $durationMinutes, in: 0...60)
                        Stepper("Seconds: \(durationSeconds)", value: $durationSeconds, in: 0...59, step: 5)
                    } else {
                        HStack {
                            Text("Distance")
                            Spacer()
                            TextField("km", value: $distanceKm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("km")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Intensity") {
                    Picker("Intensity", selection: $intensity) {
                        ForEach(Intensity.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                }

                if phaseType == .work || phaseType == .recovery {
                    Section("Repeats") {
                        Stepper("Repeat: \(repeatCount)x", value: $repeatCount, in: 1...30)
                    }
                }
            }
            .navigationTitle(existingPhase != nil ? "Edit Phase" : "Add Phase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePhase() }
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let phase = existingPhase else { return }
        phaseType = phase.phaseType
        intensity = phase.targetIntensity
        repeatCount = phase.repeatCount
        switch phase.trigger {
        case .duration(let seconds):
            triggerType = .duration
            durationMinutes = Int(seconds) / 60
            durationSeconds = Int(seconds) % 60
        case .distance(let km):
            triggerType = .distance
            distanceKm = km
        }
    }

    private func savePhase() {
        let trigger: IntervalTrigger
        if triggerType == .duration {
            let totalSeconds = TimeInterval(durationMinutes * 60 + durationSeconds)
            trigger = .duration(seconds: max(totalSeconds, 5))
        } else {
            trigger = .distance(km: max(distanceKm, 0.01))
        }

        let phase = IntervalPhase(
            id: existingPhase?.id ?? UUID(),
            phaseType: phaseType,
            trigger: trigger,
            targetIntensity: intensity,
            repeatCount: (phaseType == .work || phaseType == .recovery) ? repeatCount : 1
        )
        onSave(phase)
        dismiss()
    }
}
