import SwiftUI

// MARK: - Export, Splits, Reflection & Analysis

extension RunDetailView {

    // MARK: - Export

    func exportGPX() async {
        isExporting = true
        do {
            exportFileURL = try await exportService.exportRunAsGPX(run)
            showingShareSheet = true
        } catch {
            // Error handled silently — file just won't share
        }
        isExporting = false
    }

    func exportTrackCSV() async {
        isExporting = true
        do {
            exportFileURL = try await exportService.exportRunTrackAsCSV(run)
            showingShareSheet = true
        } catch {
            // Error handled silently
        }
        isExporting = false
    }

    func exportPDF() async {
        isExporting = true
        do {
            let athlete = try await athleteRepository.getAthlete()
            let metrics = AdvancedRunMetricsCalculator.calculate(
                run: run,
                athleteWeightKg: athlete?.weightKg,
                maxHeartRate: athlete?.maxHeartRate
            )
            let recentRuns = try await runRepository.getRecentRuns(limit: 20)
            let otherRuns = recentRuns.filter { $0.id != run.id }
            let comparison = otherRuns.isEmpty ? nil : HistoricalComparisonCalculator.compare(run: run, recentRuns: otherRuns)
            let nutrition = NutritionAnalysisCalculator.analyze(run: run)

            exportFileURL = try await exportService.exportRunAsPDF(
                run,
                metrics: metrics,
                comparison: comparison,
                nutritionAnalysis: nutrition
            )
            showingShareSheet = true
        } catch {
            // Error handled silently
        }
        isExporting = false
    }

    // MARK: - Splits

    var splitsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Splits")
                .font(.headline)

            ForEach(run.splits) { split in
                HStack {
                    Text("\(UnitFormatter.distanceLabel(units).uppercased()) \(split.kilometerNumber)")
                        .font(.subheadline.bold())
                        .frame(width: 50, alignment: .leading)

                    Text(RunStatisticsCalculator.formatPace(split.duration, unit: units))
                        .font(.subheadline.monospacedDigit())

                    Spacer()

                    if split.elevationChangeM != 0 {
                        Text(String(format: "%+.0f %@", UnitFormatter.elevationValue(split.elevationChangeM, unit: units), UnitFormatter.elevationShortLabel(units)))
                            .font(.caption)
                            .foregroundStyle(
                                split.elevationChangeM > 0
                                    ? Theme.Colors.danger
                                    : Theme.Colors.success
                            )
                    }

                    if let hr = split.averageHeartRate {
                        Text("\(hr) bpm")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)

                if split.id != run.splits.last?.id {
                    Divider()
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    // MARK: - Reflection

    @ViewBuilder
    var reflectionSection: some View {
        let currentRun = displayRun ?? run
        let hasReflection = currentRun.rpe != nil
            || currentRun.perceivedFeeling != nil
            || currentRun.terrainType != nil
        let hasNotes = currentRun.notes != nil && !currentRun.notes!.isEmpty

        if hasReflection || hasNotes {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Reflection")
                        .font(.headline)
                    Spacer()
                    Button {
                        showReflectionEdit = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                            .foregroundStyle(Theme.Colors.primary)
                    }
                    .accessibilityLabel("Edit reflection")
                    .accessibilityHint("Opens the reflection editor")
                }

                if let rpe = currentRun.rpe {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("RPE")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text("\(rpe)/10")
                            .font(.subheadline.bold())
                    }
                }

                if let feeling = currentRun.perceivedFeeling {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("Feeling")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text(feelingDisplay(feeling))
                            .font(.subheadline)
                    }
                }

                if let terrain = currentRun.terrainType {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("Terrain")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text(terrain.rawValue.capitalized)
                            .font(.subheadline)
                    }
                }

                if let notes = currentRun.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.secondaryBackground)
            )
            .sheet(isPresented: $showReflectionEdit) {
                RunReflectionEditView(
                    run: currentRun,
                    runRepository: runRepository,
                    onSave: { updatedRun in
                        displayRun = updatedRun
                    }
                )
            }
        } else {
            Button {
                showReflectionEdit = true
            } label: {
                Label("Add Reflection", systemImage: "pencil.line")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.bordered)
            .sheet(isPresented: $showReflectionEdit) {
                RunReflectionEditView(
                    run: run,
                    runRepository: runRepository,
                    onSave: { updatedRun in
                        displayRun = updatedRun
                    }
                )
            }
        }
    }

    func feelingDisplay(_ feeling: PerceivedFeeling) -> String {
        switch feeling {
        case .great: "😀 Great"
        case .good: "🙂 Good"
        case .ok: "😐 OK"
        case .tough: "😤 Tough"
        case .terrible: "😫 Terrible"
        }
    }

    // MARK: - Analysis

    var analysisLink: some View {
        NavigationLink {
            RunAnalysisView(
                run: run,
                planRepository: planRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                runRepository: runRepository,
                finishEstimateRepository: finishEstimateRepository,
                exportService: exportService
            )
        } label: {
            Label("View Analysis", systemImage: "chart.xyaxis.line")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(.borderedProminent)
    }
}
