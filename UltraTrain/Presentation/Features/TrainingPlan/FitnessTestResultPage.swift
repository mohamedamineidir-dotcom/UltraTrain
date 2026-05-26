import SwiftUI

/// Variant-specific result entry for a completed fitness test session.
/// Replaces the standard ManualValidationPage when the session is a
/// fitness test, different prompts per variant:
///
/// - VMA flat 6-min → distance covered (meters)
/// - 5K TT → finish time (mm:ss)
/// - Uphill / treadmill threshold variants → average HR + perceived
///   effort (RPE 1-10)
struct FitnessTestResultPage: View {
    let variant: FitnessTestVariant
    let onComplete: (TestResultInput, PerceivedFeeling?) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var distanceMetersText: String = ""
    @State private var minutesText: String = ""
    @State private var secondsText: String = ""
    @State private var hrText: String = ""
    @State private var rpe: Int = 7
    @State private var feeling: PerceivedFeeling? = nil
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case distance, minutes, seconds, hr }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                header
                inputCard
                feelingCard
                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle(variant.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { submit() }
                    .fontWeight(.semibold)
                    .disabled(!canSubmit)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)

            Text("How did the test go?")
                .font(.title3.bold())
            Text(promptCopy)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var promptCopy: String {
        switch variant.resultPrompt {
        case .distanceMeters:
            return "Enter the distance you covered in 6 minutes."
        case .timeSeconds:
            return "Enter your 5K finish time."
        case .heartRateAndPerceivedEffort:
            return "Enter your average heart rate over the work intervals + how it felt."
        }
    }

    // MARK: - Variant inputs

    @ViewBuilder
    private var inputCard: some View {
        switch variant.resultPrompt {
        case .distanceMeters:
            distanceInputCard
        case .timeSeconds:
            timeInputCard
        case .heartRateAndPerceivedEffort:
            hrAndEffortInputCard
        }
    }

    private var distanceInputCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Distance covered (meters)")
                .font(.headline)
            HStack {
                TextField("e.g. 1500", text: $distanceMetersText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .distance)
                    .font(.title.monospacedDigit())
                Text("m")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            if let meters = Double(distanceMetersText), meters > 0 {
                Text("VMA ≈ \(String(format: "%.1f", meters / 100.0)) km/h")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.warmCoral)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .onAppear { focusedField = .distance }
    }

    private var timeInputCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("5K finish time")
                .font(.headline)
            HStack(spacing: Theme.Spacing.sm) {
                TextField("min", text: $minutesText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .minutes)
                    .font(.title.monospacedDigit())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 80)
                Text(":")
                    .font(.title.bold())
                TextField("sec", text: $secondsText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .seconds)
                    .font(.title.monospacedDigit())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 80)
                Spacer()
            }
            if let total = totalSeconds, total > 0 {
                Text("Pace ≈ \(formatPace(total / 5)) per km")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.warmCoral)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .onAppear { focusedField = .minutes }
    }

    private var hrAndEffortInputCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Average heart rate (bpm)")
                    .font(.headline)
                HStack {
                    TextField("e.g. 168", text: $hrText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .hr)
                        .font(.title.monospacedDigit())
                    Text("bpm")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Perceived effort (1 = easy, 10 = max)")
                    .font(.headline)
                HStack {
                    Text("\(rpe)")
                        .font(.title.monospacedDigit().bold())
                        .foregroundStyle(Theme.Colors.warmCoral)
                        .frame(width: 36)
                    Slider(value: Binding(
                        get: { Double(rpe) },
                        set: { rpe = Int($0.rounded()) }
                    ), in: 1...10, step: 1)
                    .tint(Theme.Colors.warmCoral)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .onAppear { focusedField = .hr }
    }

    // MARK: - Feeling card (shared)

    private var feelingCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("How did your body feel?")
                .font(.headline)
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(PerceivedFeeling.allCases, id: \.self) { f in
                    Button {
                        feeling = f
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: f.iconName)
                                .font(.title2)
                            Text(f.shortLabel)
                                .font(.caption2)
                        }
                        .foregroundStyle(feeling == f ? Theme.Colors.warmCoral : Theme.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(feeling == f
                                    ? Theme.Colors.warmCoral.opacity(0.10)
                                    : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Submission

    private var canSubmit: Bool {
        switch variant.resultPrompt {
        case .distanceMeters:
            return Double(distanceMetersText).map { $0 > 0 } ?? false
        case .timeSeconds:
            return totalSeconds.map { $0 > 0 } ?? false
        case .heartRateAndPerceivedEffort:
            return Int(hrText).map { $0 > 30 } ?? false
        }
    }

    private var totalSeconds: TimeInterval? {
        guard let m = Int(minutesText), let s = Int(secondsText) else { return nil }
        return TimeInterval(m * 60 + s)
    }

    private func submit() {
        var input = TestResultInput()
        switch variant.resultPrompt {
        case .distanceMeters:
            input.distanceMeters = Double(distanceMetersText)
        case .timeSeconds:
            input.timeSeconds = totalSeconds
        case .heartRateAndPerceivedEffort:
            input.averageHeartRate = Int(hrText)
            input.perceivedEffortRPE = rpe
        }
        onComplete(input, feeling)
    }

    private func formatPace(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - PerceivedFeeling icon helpers

private extension PerceivedFeeling {
    var iconName: String {
        switch self {
        case .great:    "face.smiling"
        case .good:     "face.smiling.inverse"
        case .ok:       "face.dashed"
        case .tough:    "face.dashed.fill"
        case .terrible: "exclamationmark.triangle"
        }
    }

    var shortLabel: String {
        switch self {
        case .great:    "Great"
        case .good:     "Good"
        case .ok:       "OK"
        case .tough:    "Tough"
        case .terrible: "Bad"
        }
    }
}
