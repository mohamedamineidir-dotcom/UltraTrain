import SwiftUI

struct SessionDetailView: View {
    @Environment(\.unitPreference) private var units
    let session: TrainingSession
    let planStartDate: Date
    let planEndDate: Date
    let swapCandidates: [SwapCandidate]
    let athlete: Athlete?
    let nutritionAdvisor: any SessionNutritionAdvisor
    let nutritionPreferences: NutritionPreferences
    var onSkip: (() -> Void)?
    var onUnskip: (() -> Void)?
    var onReschedule: ((Date) -> Void)?
    var onSwap: ((SwapCandidate) -> Void)?

    @State private var showSkipConfirmation = false
    @State private var showRescheduleSheet = false
    @State private var showSwapSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                headerSection

                if session.isSkipped {
                    skippedBanner
                }

                statsSection
                descriptionSection

                if let athlete,
                   let advice = nutritionAdvisor.advise(
                    for: session,
                    athleteWeightKg: athlete.weightKg,
                    experienceLevel: athlete.experienceLevel,
                    preferences: nutritionPreferences
                   ) {
                    SessionNutritionSection(advice: advice)
                } else if let notes = session.nutritionNotes {
                    nutritionSection(notes)
                }

                actionsSection
            }
            .padding()
        }
        .navigationTitle(session.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Skip Session?", isPresented: $showSkipConfirmation) {
            Button("Skip", role: .destructive) { onSkip?() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This session will be marked as skipped and excluded from your weekly progress.")
        }
        .sheet(isPresented: $showRescheduleSheet) {
            RescheduleDateSheet(
                currentDate: session.date,
                planStartDate: planStartDate,
                planEndDate: planEndDate,
                onReschedule: { newDate in onReschedule?(newDate) }
            )
        }
        .sheet(isPresented: $showSwapSheet) {
            SwapSessionSheet(
                currentSession: session,
                availableSessions: swapCandidates,
                onSwap: { candidate in onSwap?(candidate) }
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: session.type.icon)
                .font(.largeTitle)
                .foregroundStyle(session.isSkipped ? Theme.Colors.secondaryLabel : session.intensity.color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(session.type.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.xs) {
                Text(session.intensity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(session.isSkipped ? Color.gray : session.intensity.color)
                    .clipShape(Capsule())

                if let zone = session.targetHeartRateZone {
                    SessionZoneTargetBadge(zone: zone)
                }
            }
        }
        .accessibilityIdentifier("trainingPlan.sessionDetail.header")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var headerAccessibilityLabel: String {
        var label = "\(session.type.displayName), \(session.intensity.displayName) intensity"
        label += ". \(session.date.formatted(.dateTime.weekday(.wide).month().day()))"
        if let zone = session.targetHeartRateZone {
            label += ". Target heart rate zone \(zone)"
        }
        if session.isSkipped {
            label += ". Skipped"
        } else if session.isCompleted {
            label += ". Completed"
        }
        return label
    }

    // MARK: - Skipped Banner

    private var skippedBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "forward.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("Skipped")
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
            Spacer()
            if onUnskip != nil {
                Button("Undo") { onUnskip?() }
                    .font(.subheadline.bold())
                    .accessibilityHint("Double-tap to restore this session")
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(.orange.opacity(0.12))
        )
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            if session.plannedDistanceKm > 0 {
                StatCard(
                    title: "Distance",
                    value: String(format: "%.1f", UnitFormatter.distanceValue(session.plannedDistanceKm, unit: units)),
                    unit: UnitFormatter.distanceLabel(units)
                )
            }
            if session.plannedElevationGainM > 0 {
                StatCard(
                    title: "Elevation",
                    value: String(format: "%.0f", UnitFormatter.elevationValue(session.plannedElevationGainM, unit: units)),
                    unit: UnitFormatter.elevationLabel(units)
                )
            }
            if session.plannedDuration > 0 {
                StatCard(
                    title: "Duration",
                    value: session.plannedDuration.formattedDuration,
                    unit: ""
                )
            }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Description")
                .font(.headline)
            Text(session.description)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func nutritionSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Nutrition", systemImage: "fork.knife")
                .font(.headline)
            Text(notes)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !session.isCompleted && !session.isSkipped {
                Button {
                    showSkipConfirmation = true
                } label: {
                    Label("Skip Session", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .accessibilityHint("Double-tap to skip this session")
            }

            if !session.isCompleted {
                Button {
                    showRescheduleSheet = true
                } label: {
                    Label("Reschedule", systemImage: "calendar.badge.clock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Double-tap to move this session to a different date")
            }

            if !session.isCompleted && !session.isSkipped {
                Button {
                    showSwapSheet = true
                } label: {
                    Label("Swap with Another Session", systemImage: "arrow.triangle.swap")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Double-tap to swap this session with another one")
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }
}
