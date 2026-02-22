import SwiftUI

struct HRZoneConfigurationView: View {
    let athlete: Athlete
    let onSave: (Athlete) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var useCustomZones: Bool
    @State private var zone1Max: Int
    @State private var zone2Max: Int
    @State private var zone3Max: Int
    @State private var zone4Max: Int

    init(athlete: Athlete, onSave: @escaping (Athlete) -> Void) {
        self.athlete = athlete
        self.onSave = onSave
        if let thresholds = athlete.customZoneThresholds, thresholds.count == 4 {
            _useCustomZones = State(initialValue: true)
            _zone1Max = State(initialValue: thresholds[0])
            _zone2Max = State(initialValue: thresholds[1])
            _zone3Max = State(initialValue: thresholds[2])
            _zone4Max = State(initialValue: thresholds[3])
        } else {
            let maxHR = athlete.maxHeartRate
            _useCustomZones = State(initialValue: false)
            _zone1Max = State(initialValue: Int(Double(maxHR) * 0.60))
            _zone2Max = State(initialValue: Int(Double(maxHR) * 0.70))
            _zone3Max = State(initialValue: Int(Double(maxHR) * 0.80))
            _zone4Max = State(initialValue: Int(Double(maxHR) * 0.90))
        }
    }

    var body: some View {
        Form {
            toggleSection
            if useCustomZones {
                customZoneBoundaries
            }
            zonePreviewSection
        }
        .navigationTitle("HR Zones")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .accessibilityHint("Saves your heart rate zone configuration")
            }
        }
    }

    // MARK: - Toggle

    private var toggleSection: some View {
        Section {
            Toggle("Custom HR Zones", isOn: $useCustomZones.animation())
                .accessibilityHint("When enabled, you can set custom heart rate boundaries for each zone")
        } footer: {
            Text("When off, zones are calculated as percentages of your max HR (\(athlete.maxHeartRate) bpm).")
        }
    }

    // MARK: - Custom Boundaries

    private var customZoneBoundaries: some View {
        Section("Zone Boundaries (BPM)") {
            Stepper("Zone 1 max: \(zone1Max) bpm", value: $zone1Max, in: 80...zone2Max - 1)
                .accessibilityValue(AccessibilityFormatters.heartRate(zone1Max))
                .accessibilityHint("Adjust the upper limit for Zone 1 Recovery")
            Stepper("Zone 2 max: \(zone2Max) bpm", value: $zone2Max, in: zone1Max + 1...zone3Max - 1)
                .accessibilityValue(AccessibilityFormatters.heartRate(zone2Max))
                .accessibilityHint("Adjust the upper limit for Zone 2 Aerobic")
            Stepper("Zone 3 max: \(zone3Max) bpm", value: $zone3Max, in: zone2Max + 1...zone4Max - 1)
                .accessibilityValue(AccessibilityFormatters.heartRate(zone3Max))
                .accessibilityHint("Adjust the upper limit for Zone 3 Tempo")
            Stepper("Zone 4 max: \(zone4Max) bpm", value: $zone4Max, in: zone3Max + 1...athlete.maxHeartRate)
                .accessibilityValue(AccessibilityFormatters.heartRate(zone4Max))
                .accessibilityHint("Adjust the upper limit for Zone 4 Threshold")
        }
    }

    // MARK: - Preview

    private var zonePreviewSection: some View {
        Section("Zone Preview") {
            if useCustomZones {
                zoneRow(zone: 1, name: "Recovery", range: "≤ \(zone1Max) bpm", color: Theme.Colors.zone1)
                zoneRow(zone: 2, name: "Aerobic", range: "\(zone1Max + 1)–\(zone2Max) bpm", color: Theme.Colors.zone2)
                zoneRow(zone: 3, name: "Tempo", range: "\(zone2Max + 1)–\(zone3Max) bpm", color: Theme.Colors.zone3)
                zoneRow(zone: 4, name: "Threshold", range: "\(zone3Max + 1)–\(zone4Max) bpm", color: Theme.Colors.zone4)
                zoneRow(zone: 5, name: "VO2max", range: "> \(zone4Max) bpm", color: Theme.Colors.zone5)
            } else {
                let maxHR = athlete.maxHeartRate
                zoneRow(zone: 1, name: "Recovery", range: "\(pct(0.50, maxHR))–\(pct(0.60, maxHR)) bpm (50–60%)", color: Theme.Colors.zone1)
                zoneRow(zone: 2, name: "Aerobic", range: "\(pct(0.60, maxHR))–\(pct(0.70, maxHR)) bpm (60–70%)", color: Theme.Colors.zone2)
                zoneRow(zone: 3, name: "Tempo", range: "\(pct(0.70, maxHR))–\(pct(0.80, maxHR)) bpm (70–80%)", color: Theme.Colors.zone3)
                zoneRow(zone: 4, name: "Threshold", range: "\(pct(0.80, maxHR))–\(pct(0.90, maxHR)) bpm (80–90%)", color: Theme.Colors.zone4)
                zoneRow(zone: 5, name: "VO2max", range: "\(pct(0.90, maxHR))–\(maxHR) bpm (90–100%)", color: Theme.Colors.zone5)
            }
        }
    }

    private func zoneRow(zone: Int, name: String, range: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 6, height: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Zone \(zone) — \(name)")
                    .font(.subheadline.bold())
                Text(range)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers

    private func pct(_ fraction: Double, _ maxHR: Int) -> Int {
        Int(Double(maxHR) * fraction)
    }

    private func save() {
        var updated = athlete
        updated.customZoneThresholds = useCustomZones
            ? [zone1Max, zone2Max, zone3Max, zone4Max]
            : nil
        onSave(updated)
        dismiss()
    }
}
