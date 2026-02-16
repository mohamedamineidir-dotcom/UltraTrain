import SwiftUI

struct SessionDetailView: View {
    let session: TrainingSession
    let planStartDate: Date
    let planEndDate: Date
    let swapCandidates: [SwapCandidate]
    let athlete: Athlete?
    let nutritionAdvisor: any SessionNutritionAdvisor
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
                    experienceLevel: athlete.experienceLevel
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

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(session.type.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Text(session.intensity.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(session.isSkipped ? Color.gray : session.intensity.color)
                .clipShape(Capsule())
        }
    }

    // MARK: - Skipped Banner

    private var skippedBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "forward.fill")
                .foregroundStyle(.orange)
            Text("Skipped")
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
            Spacer()
            if onUnskip != nil {
                Button("Undo") { onUnskip?() }
                    .font(.subheadline.bold())
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
                    value: String(format: "%.1f", session.plannedDistanceKm),
                    unit: "km"
                )
            }
            if session.plannedElevationGainM > 0 {
                StatCard(
                    title: "Elevation",
                    value: String(format: "%.0f", session.plannedElevationGainM),
                    unit: "m D+"
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
            }

            if !session.isCompleted {
                Button {
                    showRescheduleSheet = true
                } label: {
                    Label("Reschedule", systemImage: "calendar.badge.clock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if !session.isCompleted && !session.isSkipped {
                Button {
                    showSwapSheet = true
                } label: {
                    Label("Swap with Another Session", systemImage: "arrow.triangle.swap")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }
}
