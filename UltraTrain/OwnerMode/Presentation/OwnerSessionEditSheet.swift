#if OWNER_MODE
import SwiftUI

/// Owner-only sheet for freely editing a generated session's planned
/// values (distance, elevation, duration, pace) and, when the session
/// has a structured interval/fractionné workout attached, each block's
/// target pace. On save, hands an `OwnerSessionEdit` back to the
/// caller — only the fields the owner actually changed are populated,
/// everything else is left as generated.
struct OwnerSessionEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let session: TrainingSession
    let workout: IntervalWorkout?
    let onSave: (OwnerSessionEdit) -> Void

    @State private var distanceKmText: String = ""
    @State private var elevationMText: String = ""
    @State private var durationMinutesText: String = ""
    @State private var targetPaceText: String = ""
    @State private var phasePaceTexts: [UUID: String] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section("Volume") {
                    LabeledContent("Distance (km)") {
                        TextField("km", text: $distanceKmText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Elevation gain (m)") {
                        TextField("m", text: $elevationMText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Duration (min)") {
                        TextField("min", text: $durationMinutesText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    LabeledContent("Target pace (min/km)") {
                        TextField("e.g. 5:30", text: $targetPaceText)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text("Setting a pace fills in distance or duration automatically from whichever one you leave blank.")
                }

                if let workout, !workout.phases.isEmpty {
                    Section("Block paces") {
                        ForEach(workout.phases) { phase in
                            LabeledContent(phaseLabel(phase)) {
                                TextField(
                                    "min/km",
                                    text: Binding(
                                        get: { phasePaceTexts[phase.id, default: ""] },
                                        set: { phasePaceTexts[phase.id] = $0 }
                                    )
                                )
                                .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Owner Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: populateInitialValues)
        }
    }

    private func phaseLabel(_ phase: IntervalPhase) -> String {
        let repeatPrefix = phase.repeatCount > 1 ? "\(phase.repeatCount)x " : ""
        return "\(repeatPrefix)\(phase.phaseType.rawValue.capitalized) (\(phase.trigger.displayText))"
    }

    private func populateInitialValues() {
        if session.plannedDistanceKm > 0 { distanceKmText = String(format: "%.2f", session.plannedDistanceKm) }
        if session.plannedElevationGainM > 0 { elevationMText = String(format: "%.0f", session.plannedElevationGainM) }
        if session.plannedDuration > 0 { durationMinutesText = String(format: "%.0f", session.plannedDuration / 60) }
    }

    private func save() {
        var edit = OwnerSessionEdit()
        edit.plannedDistanceKm = Double(distanceKmText.trimmingCharacters(in: .whitespaces))
        edit.plannedElevationGainM = Double(elevationMText.trimmingCharacters(in: .whitespaces))
        if let minutes = Double(durationMinutesText.trimmingCharacters(in: .whitespaces)) {
            edit.plannedDuration = minutes * 60
        }
        edit.targetPaceSecondsPerKm = OwnerPaceTextParser.secondsPerKm(from: targetPaceText)

        edit.phasePaces = phasePaceTexts.compactMap { phaseId, text in
            guard let pace = OwnerPaceTextParser.secondsPerKm(from: text) else { return nil }
            return OwnerPhasePaceEdit(phaseId: phaseId, paceSecondsPerKm: pace)
        }

        onSave(edit)
        dismiss()
    }
}

/// Parses a "mm:ss" or plain-minutes pace string (e.g. "5:30" or "5.5")
/// into seconds/km. Returns nil for empty/unparseable input, which the
/// caller treats as "leave unchanged."
enum OwnerPaceTextParser {
    static func secondsPerKm(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":")
            guard parts.count == 2,
                  let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]) else { return nil }
            return minutes * 60 + seconds
        }

        guard let minutes = Double(trimmed) else { return nil }
        return minutes * 60
    }
}
#endif
