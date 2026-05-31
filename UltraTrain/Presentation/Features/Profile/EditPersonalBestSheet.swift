import SwiftUI

/// Sheet for adding or updating a personal record at one of the four
/// standard road distances. Pre-populates from any existing PR at the
/// selected distance, the athlete can replace or edit it.
struct EditPersonalBestSheet: View {
    @Environment(\.dismiss) private var dismiss

    let presetDistance: PersonalBestDistance?
    let athlete: Athlete?
    let onSave: (PersonalBest) -> Void

    @State private var distance: PersonalBestDistance
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var date: Date

    init(
        presetDistance: PersonalBestDistance?,
        athlete: Athlete?,
        onSave: @escaping (PersonalBest) -> Void
    ) {
        self.presetDistance = presetDistance
        self.athlete = athlete
        self.onSave = onSave

        let initialDistance = presetDistance ?? .tenK
        _distance = State(initialValue: initialDistance)

        let existing = athlete?.personalBests.first { $0.distance == initialDistance }
        let totalSeconds = Int((existing?.timeSeconds ?? 0).rounded())
        _hours = State(initialValue: totalSeconds / 3600)
        _minutes = State(initialValue: (totalSeconds % 3600) / 60)
        _seconds = State(initialValue: totalSeconds % 60)
        _date = State(initialValue: existing?.date ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        String(localized: "pr.edit.distance", defaultValue: "Distance"),
                        selection: $distance
                    ) {
                        ForEach(PersonalBestDistance.allCases, id: \.self) { d in
                            Text(d.shortLabel).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: distance) { _, new in
                        // Re-prefill from any existing PR at the new distance.
                        let existing = athlete?.personalBests.first { $0.distance == new }
                        let totalSeconds = Int((existing?.timeSeconds ?? 0).rounded())
                        hours = totalSeconds / 3600
                        minutes = (totalSeconds % 3600) / 60
                        seconds = totalSeconds % 60
                        if let existing { date = existing.date }
                    }
                }

                Section(String(localized: "pr.edit.time", defaultValue: "Time")) {
                    HStack(spacing: Theme.Spacing.sm) {
                        timeColumn(
                            label: String(localized: "common.hours", defaultValue: "h"),
                            value: $hours,
                            range: 0...9
                        )
                        timeColumn(
                            label: String(localized: "common.minutes", defaultValue: "m"),
                            value: $minutes,
                            range: 0...59
                        )
                        timeColumn(
                            label: String(localized: "common.seconds", defaultValue: "s"),
                            value: $seconds,
                            range: 0...59
                        )
                    }
                }

                Section {
                    DatePicker(
                        String(localized: "pr.edit.date", defaultValue: "Date"),
                        selection: $date,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle(Text(
                String(localized: "pr.edit.title", defaultValue: "Log a PR")
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", defaultValue: "Save")) {
                        let total = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                        guard total > 0 else { return }
                        let pr = PersonalBest(
                            id: UUID(),
                            distance: distance,
                            timeSeconds: total,
                            date: date
                        )
                        onSave(pr)
                        dismiss()
                    }
                    .disabled(hours * 3600 + minutes * 60 + seconds <= 0)
                }
            }
        }
    }

    private func timeColumn(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        VStack(spacing: 2) {
            Picker(label, selection: value) {
                ForEach(range, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .clipped()
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
