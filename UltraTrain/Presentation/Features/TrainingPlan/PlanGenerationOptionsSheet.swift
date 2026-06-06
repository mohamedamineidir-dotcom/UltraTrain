import SwiftUI
import os

/// Pre-plan options sheet shown when the athlete clicks "Generate plan".
/// Plan-scoped: the answers can differ per prep cycle, so we ask each
/// time rather than freezing them on the athlete profile.
///
/// Split into a 2- or 3-step wizard (the fitness-test step is hidden
/// when the race / plan length make it irrelevant). One focused
/// question per step so the screen stays light to read.
struct PlanGenerationOptionsSheet: View {

    let targetRace: Race
    let athlete: Athlete
    let planTotalWeeks: Int
    let raceRepository: any RaceRepository
    let onGenerate: (PlanGenerationOptions) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var includeFitnessTest: Bool
    @State private var recentFitnessChange: RecentFitnessChange = .none
    @State private var stepIndex: Int = 0
    @State private var intermediateRaces: [Race] = []
    @State private var showAddRaceSheet = false
    @State private var raceToEdit: Race?
    @State private var isLoadingRaces = false

    private let backdrop = Color(red: 0.05, green: 0.05, blue: 0.09)
    private let logger = Logger.training

    init(
        targetRace: Race,
        athlete: Athlete,
        planTotalWeeks: Int,
        raceRepository: any RaceRepository,
        onGenerate: @escaping (PlanGenerationOptions) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.targetRace = targetRace
        self.athlete = athlete
        self.planTotalWeeks = planTotalWeeks
        self.raceRepository = raceRepository
        self.onGenerate = onGenerate
        self.onCancel = onCancel
        _includeFitnessTest = State(initialValue: FitnessTestScheduler.defaultOptIn(
            targetRace: targetRace,
            athlete: athlete,
            planTotalWeeks: planTotalWeeks
        ))
    }

    private var offersFitnessTest: Bool {
        FitnessTestScheduler.shouldOfferTest(
            targetRace: targetRace, planTotalWeeks: planTotalWeeks
        )
    }

    private var totalSteps: Int { offersFitnessTest ? 3 : 2 }
    private var isLastStep: Bool { stepIndex == totalSteps - 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                backdrop.ignoresSafeArea()

                VStack(spacing: 0) {
                    progressIndicator
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.sm)

                    ScrollView {
                        VStack(spacing: Theme.Spacing.xl) {
                            header
                            currentStepContent
                                .id(stepIndex)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            Color.clear.frame(height: 80)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    }

                    bottomBar
                }
            }
            .environment(\.colorScheme, .dark)
            .presentationBackground(backdrop)
            .navigationTitle("Plan options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel(); dismiss()
                    }
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .task {
                await loadIntermediateRaces()
            }
            .sheet(isPresented: $showAddRaceSheet) {
                EditRaceSheet(mode: .add) { newRace in
                    Task { await saveRace(newRace, isNew: true) }
                }
            }
            .sheet(item: $raceToEdit) { race in
                EditRaceSheet(mode: .edit(race)) { updated in
                    Task { await saveRace(updated, isNew: false) }
                }
            }
        }
    }

    // MARK: - Progress indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { idx in
                Capsule()
                    .fill(idx == stepIndex
                          ? Theme.Colors.warmCoral
                          : Color.white.opacity(0.18))
                    .frame(height: 4)
                    .animation(.easeOut(duration: 0.2), value: stepIndex)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.Colors.warmCoral.opacity(0.30), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.5), radius: 12, y: 6)
            }

            VStack(spacing: 6) {
                Text("Tune your plan")
                    .font(.title.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("A few quick checks so your plan starts where you really are.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Step routing

    @ViewBuilder
    private var currentStepContent: some View {
        switch (stepIndex, offersFitnessTest) {
        case (0, _):
            fitnessChangeSection
        case (1, true):
            fitnessTestSection
        case (1, false):
            intermediateRacesSection
        case (2, true):
            intermediateRacesSection
        default:
            EmptyView()
        }
    }

    // MARK: - Step 1, Recent fitness change

    private var fitnessChangeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(
                icon: "calendar.badge.clock",
                tint: Theme.Colors.warmCoral,
                title: "How were the last 4 weeks?",
                subtitle: "Injury, illness, or time off changes how aggressively we should ramp."
            )

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(RecentFitnessChange.allCases, id: \.self) { option in
                    fitnessChangeRow(option)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.warmCoral)
    }

    private func fitnessChangeRow(_ option: RecentFitnessChange) -> some View {
        let isSelected = recentFitnessChange == option
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                recentFitnessChange = option
            }
        } label: {
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.warmCoral : Color.white.opacity(0.07))
                        .frame(width: 36, height: 36)
                    Image(systemName: optionIcon(option))
                        .font(.body.bold())
                        .foregroundStyle(isSelected ? .white : Theme.Colors.secondaryLabel)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(optionTitle(option)))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(LocalizedStringKey(optionEffect(option)))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.warmCoral)
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Theme.Colors.warmCoral.opacity(0.13) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(
                        isSelected ? Theme.Colors.warmCoral.opacity(0.6) : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2, Mid-prep fitness test

    private var fitnessTestSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(
                icon: "speedometer",
                tint: Theme.Colors.primary,
                title: "Mid-prep fitness test",
                subtitle: testTypeBlurb
            )

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    includeFitnessTest.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(includeFitnessTest ? "Scheduled around week 4-5" : "Skip the test"))
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(LocalizedStringKey(includeFitnessTest ? "Recalibrates your pace targets" : "Plan keeps current pace anchors"))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    Spacer()
                    customToggle
                }
                .padding(.vertical, Theme.Spacing.sm)
                .padding(.horizontal, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if includeFitnessTest {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.primary)
                    Text(LocalizedStringKey(testDetailBlurb))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.primary.opacity(0.10))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.primary)
    }

    private var customToggle: some View {
        ZStack(alignment: includeFitnessTest ? .trailing : .leading) {
            Capsule()
                .fill(includeFitnessTest ? Theme.Colors.primary : Color.white.opacity(0.18))
                .frame(width: 50, height: 30)
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .padding(.horizontal, 2)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
    }

    // MARK: - Step 3, Intermediate (B/C) races

    private var intermediateRacesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(
                icon: "flag.checkered",
                tint: Theme.Colors.info,
                title: "Races during prep?",
                subtitle: "Adding any B or C races now lets the plan shape its build, taper and recovery around them."
            )

            if intermediateRaces.isEmpty {
                emptyRacesState
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(intermediateRaces) { race in
                        raceRow(race)
                    }
                }
            }

            addRaceButton
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.info)
    }

    private var emptyRacesState: some View {
        VStack(spacing: 6) {
            Image(systemName: "flag.slash")
                .font(.title3)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("No races added yet")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Text("Just the A-race? Tap continue. Otherwise add them below.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func raceRow(_ race: Race) -> some View {
        Button {
            raceToEdit = race
        } label: {
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(race.priority.badgeColor.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Text(priorityLetter(race.priority))
                        .font(.subheadline.bold())
                        .foregroundStyle(race.priority.badgeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(race.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(raceMetaLine(race))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var addRaceButton: some View {
        Button {
            showAddRaceSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.body.bold())
                Text(intermediateRaces.isEmpty ? "Add a race" : "Add another race")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(Theme.Colors.info)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .background(
                Capsule()
                    .fill(Theme.Colors.info.opacity(0.10))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Theme.Colors.info.opacity(0.55), Theme.Colors.info.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section header

    private func sectionHeader(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(tint))
                .shadow(color: tint.opacity(0.4), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(LocalizedStringKey(subtitle))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [backdrop.opacity(0), backdrop],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            HStack(spacing: Theme.Spacing.sm) {
                if stepIndex > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stepIndex -= 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .fill(Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    handleAdvance()
                } label: {
                    HStack(spacing: 8) {
                        Text(isLastStep ? "Generate plan" : "Continue")
                            .font(.headline.bold())
                        Image(systemName: isLastStep ? "sparkles" : "chevron.right")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Gradients.warmCoralCTA)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.4), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.md)
            .background(backdrop)
        }
    }

    private func handleAdvance() {
        if isLastStep {
            let options = PlanGenerationOptions(
                includeFitnessTest: includeFitnessTest,
                recentFitnessChange: recentFitnessChange == .none ? nil : recentFitnessChange
            )
            onGenerate(options)
            dismiss()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                stepIndex += 1
            }
        }
    }

    // MARK: - Race repo I/O

    private func loadIntermediateRaces() async {
        isLoadingRaces = true
        defer { isLoadingRaces = false }
        do {
            let all = try await raceRepository.getRaces()
            intermediateRaces = all
                .filter { $0.id != targetRace.id && $0.date < targetRace.date && $0.priority != .aRace }
                .sorted { $0.date < $1.date }
        } catch {
            logger.error("PlanGenerationOptionsSheet: failed to load races: \(error.localizedDescription)")
        }
    }

    private func saveRace(_ race: Race, isNew: Bool) async {
        do {
            if isNew {
                try await raceRepository.saveRace(race)
            } else {
                try await raceRepository.updateRace(race)
            }
            await loadIntermediateRaces()
        } catch {
            logger.error("PlanGenerationOptionsSheet: failed to save race: \(error.localizedDescription)")
        }
    }

    // MARK: - Display helpers

    private func optionTitle(_ option: RecentFitnessChange) -> String {
        switch option {
        case .none:        "Training as usual"
        case .minor:       "Light setback"
        case .moderate:    "Moderate setback"
        case .significant: "Major setback"
        }
    }

    private func optionEffect(_ option: RecentFitnessChange) -> String {
        switch option {
        case .none:        "Plan ramps as designed."
        case .minor:       "1-2 weeks reduced. Plan eases the first 1-2 weeks."
        case .moderate:    "2-4 weeks off or managed injury. Conservative ramp."
        case .significant: "4+ weeks off. Plan rebuilds gradually from the base."
        }
    }

    private func optionIcon(_ option: RecentFitnessChange) -> String {
        switch option {
        case .none:        "checkmark"
        case .minor:       "leaf.fill"
        case .moderate:    "cross.case.fill"
        case .significant: "arrow.uturn.left"
        }
    }

    private func priorityLetter(_ priority: RacePriority) -> String {
        switch priority {
        case .aRace: "A"
        case .bRace: "B"
        case .cRace: "C"
        }
    }

    private func raceMetaLine(_ race: Race) -> String {
        let date = race.date.formatted(.dateTime.month(.abbreviated).day())
        let dist = Int(race.distanceKm.rounded())
        return "\(race.priority.displayName) · \(date) · \(dist) km"
    }

    private var testTypeBlurb: String {
        let variant = FitnessTestScheduler.pickVariant(targetRace: targetRace, athlete: athlete)
        return String(localized: "planOpts.testTypeBlurb",
                      defaultValue: "Around week 4-5 we'll schedule a \(variant.displayName.lowercased()) to recalibrate your training paces.")
    }

    private var testDetailBlurb: String {
        switch FitnessTestScheduler.pickVariant(targetRace: targetRace, athlete: athlete) {
        case .vmaFlat6Min:
            return "6 min all-out on flat (track ideal). Distance covered ÷ 100 = your VMA. Re-anchors all training paces."
        case .fiveKTT:
            return "5K time trial all-out. Result re-anchors all your pace targets."
        case .uphillSustained30Min:
            return "30 min uphill at threshold effort on a sustained climb. Calibrates your trail threshold zones."
        case .uphillRepeats4x8:
            return "4 × 6-8 min uphill at threshold effort, jog-down recovery. Threshold calibration when you don't have a 30-min sustained climb."
        case .uphillRepeats6x4:
            return "5-6 × 4 min uphill at threshold effort. Threshold calibration for shorter hills."
        case .treadmillIncline30Min:
            return "30 min on a treadmill at 8-12% incline at threshold effort. Designed for flat-region athletes prepping for mountain races."
        }
    }
}
