import SwiftUI

struct SessionValidationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units

    let session: TrainingSession
    let recentRuns: [CompletedRun]
    let onComplete: (Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void
    let onLinkRun: (UUID) -> Void
    var recentRunsProvider: ((Date) async -> [CompletedRun])?

    @State private var distanceText: String
    @State private var hours: Int
    @State private var minutes: Int
    @State private var elevationText: String
    @State private var feeling: PerceivedFeeling?
    @State private var rpe: Int?
    @State private var loadedRuns: [CompletedRun]?

    init(
        session: TrainingSession,
        recentRuns: [CompletedRun] = [],
        onComplete: @escaping (Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void,
        onLinkRun: @escaping (UUID) -> Void,
        recentRunsProvider: ((Date) async -> [CompletedRun])? = nil
    ) {
        self.session = session
        self.recentRuns = recentRuns
        self.onComplete = onComplete
        self.onLinkRun = onLinkRun
        self.recentRunsProvider = recentRunsProvider
        let planned = session.plannedDuration
        _distanceText = State(initialValue: session.plannedDistanceKm > 0
            ? String(format: "%.1f", session.plannedDistanceKm) : "")
        _hours = State(initialValue: Int(planned) / 3600)
        _minutes = State(initialValue: (Int(planned) % 3600) / 60)
        _elevationText = State(initialValue: session.plannedElevationGainM > 0
            ? String(format: "%.0f", session.plannedElevationGainM) : "")
    }

    private var runs: [CompletedRun] {
        loadedRuns ?? recentRuns
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    sessionHeader
                    statsEntrySection
                    feelingSection
                    rpeSection
                    if !runs.isEmpty {
                        recentRunsSection
                    }
                    completeButton
                    skipButton
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Complete Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if let provider = recentRunsProvider {
                    loadedRuns = await provider(session.date)
                }
            }
        }
    }

    // MARK: - Session Header

    private var sessionHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: session.type.icon)
                .font(.title2)
                .foregroundStyle(session.intensity.color)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(session.intensity.color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.displayName)
                    .font(.title3.bold())
                Text(session.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            if session.isKeySession {
                Text("Key")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.accentColor)
                    .clipShape(Capsule())
            }
        }
        .futuristicGlassStyle()
    }

    // MARK: - Stats Entry

    private var statsEntrySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Session Stats")
                .font(.headline)

            VStack(spacing: Theme.Spacing.sm) {
                // Distance
                HStack {
                    Label("Distance", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.subheadline)
                    Spacer()
                    TextField("km", text: $distanceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("km")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                // Duration
                HStack {
                    Label("Duration", systemImage: "clock")
                        .font(.subheadline)
                    Spacer()
                    Picker("Hours", selection: $hours) {
                        ForEach(0..<24, id: \.self) { h in
                            Text("\(h)h").tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 65)
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { m in
                            Text("\(m)m").tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 65)
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                // Elevation
                HStack {
                    Label("Elevation", systemImage: "mountain.2.fill")
                        .font(.subheadline)
                    Spacer()
                    TextField("m", text: $elevationText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("m D+")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
            }
        }
        .futuristicGlassStyle()
    }

    // MARK: - Feeling Section

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("How Did It Feel?")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(PerceivedFeeling.allCases, id: \.self) { f in
                    Button {
                        feeling = feeling == f ? nil : f
                    } label: {
                        VStack(spacing: 4) {
                            Text(emoji(for: f))
                                .font(.title2)
                            Text(label(for: f))
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(
                                    feeling == f
                                        ? Theme.Colors.primary.opacity(0.15)
                                        : Theme.Colors.secondaryBackground
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(
                                    feeling == f ? Theme.Colors.primary : .clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label(for: f))\(feeling == f ? ", selected" : "")")
                }
            }
        }
        .futuristicGlassStyle()
    }

    // MARK: - RPE Section

    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Rate Your Effort (RPE)")
                .font(.headline)

            HStack(spacing: Theme.Spacing.xs) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        rpe = rpe == value ? nil : value
                    } label: {
                        Text("\(value)")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .fill(
                                        rpe == value
                                            ? rpeColor(value)
                                            : Theme.Colors.secondaryBackground
                                    )
                            )
                            .foregroundStyle(
                                rpe == value ? .white : Theme.Colors.label
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("RPE \(value)\(rpe == value ? ", selected" : "")")
                }
            }

            HStack {
                Text("Easy")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                Text("Maximum")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .futuristicGlassStyle()
    }

    // MARK: - Recent Runs

    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Link to a Recent Run")
                .font(.headline)

            ForEach(runs) { run in
                Button {
                    onLinkRun(run.id)
                    dismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "figure.run")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Theme.Colors.secondaryLabel)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(run.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.subheadline.weight(.medium))
                            HStack(spacing: Theme.Spacing.xs) {
                                Text(formatDuration(run.duration))
                                if run.distanceKm > 0 {
                                    Text("·")
                                    Text(String(format: "%.1f km", run.distanceKm))
                                }
                                if run.elevationGainM > 0 {
                                    Text("·")
                                    Text(String(format: "%.0fm D+", run.elevationGainM))
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        }

                        Spacer()

                        Image(systemName: "link.badge.plus")
                            .foregroundStyle(Theme.Colors.accentColor)
                    }
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                }
                .buttonStyle(.plain)
            }
        }
        .futuristicGlassStyle()
    }

    // MARK: - Action Buttons

    private var completeButton: some View {
        Button {
            let dist = Double(distanceText.replacingOccurrences(of: ",", with: "."))
            let dur = TimeInterval(hours * 3600 + minutes * 60)
            let elev = Double(elevationText)
            onComplete(dist, dur > 0 ? dur : nil, elev, feeling, rpe)
            dismiss()
        } label: {
            Label("Complete Session", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .foregroundStyle(.white)
                .background(Theme.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    private var skipButton: some View {
        Button {
            onComplete(nil, nil, nil, feeling, rpe)
            dismiss()
        } label: {
            Text("Skip Stats — Mark Complete")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Helpers

    private func emoji(for feeling: PerceivedFeeling) -> String {
        switch feeling {
        case .great: "😀"
        case .good: "🙂"
        case .ok: "😐"
        case .tough: "😤"
        case .terrible: "😫"
        }
    }

    private func label(for feeling: PerceivedFeeling) -> String {
        switch feeling {
        case .great: "Great"
        case .good: "Good"
        case .ok: "OK"
        case .tough: "Tough"
        case .terrible: "Terrible"
        }
    }

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...3: Theme.Colors.success
        case 4...6: Theme.Colors.warning
        case 7...8: .orange
        default: Theme.Colors.danger
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(minutes)min"
    }
}
