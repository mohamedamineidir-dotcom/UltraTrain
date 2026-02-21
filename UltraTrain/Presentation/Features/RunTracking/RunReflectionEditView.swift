import SwiftUI

struct RunReflectionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RunReflectionEditViewModel

    let onSave: ((CompletedRun) -> Void)?

    init(
        run: CompletedRun,
        runRepository: any RunRepository,
        onSave: ((CompletedRun) -> Void)? = nil
    ) {
        self.onSave = onSave
        _viewModel = State(
            initialValue: RunReflectionEditViewModel(
                run: run,
                runRepository: runRepository
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    rpeSection
                    feelingSection
                    terrainSection
                    notesSection
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Run Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            if viewModel.didSave {
                                onSave?(viewModel.run)
                                dismiss()
                            }
                        }
                    }
                    .bold()
                    .disabled(viewModel.isSaving)
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    // MARK: - RPE Section

    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Rate of Perceived Exertion")
                .font(.headline)

            HStack(spacing: Theme.Spacing.xs) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        viewModel.rpe = viewModel.rpe == value ? nil : value
                    } label: {
                        Text("\(value)")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .fill(
                                        viewModel.rpe == value
                                            ? rpeColor(value)
                                            : Theme.Colors.secondaryBackground
                                    )
                            )
                            .foregroundStyle(
                                viewModel.rpe == value
                                    ? .white
                                    : Theme.Colors.label
                            )
                    }
                    .buttonStyle(.plain)
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
    }

    // MARK: - Feeling Section

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("How Did It Feel?")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(PerceivedFeeling.allCases, id: \.self) { feeling in
                    Button {
                        viewModel.perceivedFeeling = viewModel.perceivedFeeling == feeling
                            ? nil
                            : feeling
                    } label: {
                        VStack(spacing: 4) {
                            Text(emoji(for: feeling))
                                .font(.title2)
                            Text(label(for: feeling))
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(
                                    viewModel.perceivedFeeling == feeling
                                        ? Theme.Colors.primary.opacity(0.15)
                                        : Theme.Colors.secondaryBackground
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(
                                    viewModel.perceivedFeeling == feeling
                                        ? Theme.Colors.primary
                                        : .clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Terrain Section

    private var terrainSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Terrain")
                .font(.headline)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(TerrainType.allCases, id: \.self) { terrain in
                    Button {
                        viewModel.terrainType = viewModel.terrainType == terrain
                            ? nil
                            : terrain
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: terrainIcon(for: terrain))
                                .font(.title3)
                            Text(terrainLabel(for: terrain))
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(
                                    viewModel.terrainType == terrain
                                        ? Theme.Colors.primary.opacity(0.15)
                                        : Theme.Colors.secondaryBackground
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(
                                    viewModel.terrainType == terrain
                                        ? Theme.Colors.primary
                                        : .clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Notes")
                .font(.headline)
            TextField(
                "How did the run go? Key learnings?",
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(3...6)
            .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Helpers

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...3: return Theme.Colors.success
        case 4...6: return Theme.Colors.warning
        case 7...8: return .orange
        default: return Theme.Colors.danger
        }
    }

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

    private func terrainIcon(for terrain: TerrainType) -> String {
        switch terrain {
        case .road: "road.lanes"
        case .trail: "figure.hiking"
        case .mountain: "mountain.2.fill"
        case .mixed: "arrow.triangle.branch"
        }
    }

    private func terrainLabel(for terrain: TerrainType) -> String {
        switch terrain {
        case .road: "Road"
        case .trail: "Trail"
        case .mountain: "Mountain"
        case .mixed: "Mixed"
        }
    }
}
