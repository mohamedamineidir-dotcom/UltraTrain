import SwiftUI

struct MorningCheckInSheet: View {
    @State private var viewModel: MorningCheckInViewModel
    @Environment(\.dismiss) private var dismiss

    init(morningCheckInRepository: any MorningCheckInRepository) {
        _viewModel = State(initialValue: MorningCheckInViewModel(
            morningCheckInRepository: morningCheckInRepository
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ratingSection(
                        title: "Energy Level",
                        value: $viewModel.perceivedEnergy,
                        labels: ["Exhausted", "Low", "Moderate", "Good", "Excellent"],
                        emojis: ["😴", "😔", "😐", "😊", "⚡️"]
                    )

                    ratingSection(
                        title: "Muscle Soreness",
                        value: $viewModel.muscleSoreness,
                        labels: ["None", "Mild", "Moderate", "Sore", "Very Sore"],
                        emojis: ["💪", "🙂", "😐", "😣", "🤕"]
                    )

                    ratingSection(
                        title: "Mood",
                        value: $viewModel.mood,
                        labels: ["Very Low", "Low", "Neutral", "Good", "Great"],
                        emojis: ["😞", "😕", "😐", "😊", "😄"]
                    )

                    ratingSection(
                        title: "Sleep Quality",
                        value: $viewModel.sleepQualitySubjective,
                        labels: ["Terrible", "Poor", "Fair", "Good", "Excellent"],
                        emojis: ["😵", "😴", "😐", "😌", "😇"]
                    )

                    Section("Notes (optional)") {
                        TextField("How are you feeling?", text: $viewModel.notes, axis: .vertical)
                            .lineLimit(3...5)
                    }
                }
            }
            .navigationTitle("Morning Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            if viewModel.didSave { dismiss() }
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .task { await viewModel.loadTodaysCheckIn() }
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

    // MARK: - Rating Section

    private func ratingSection(
        title: String,
        value: Binding<Int>,
        labels: [String],
        emojis: [String]
    ) -> some View {
        Section(title) {
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            value.wrappedValue = level
                        } label: {
                            VStack(spacing: 4) {
                                Text(emojis[level - 1])
                                    .font(.title2)
                                Text(labels[level - 1])
                                    .font(.caption2)
                                    .foregroundStyle(
                                        value.wrappedValue == level
                                            ? Theme.Colors.primary
                                            : Theme.Colors.secondaryLabel
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .fill(value.wrappedValue == level
                                          ? Theme.Colors.primary.opacity(0.15)
                                          : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .stroke(value.wrappedValue == level
                                            ? Theme.Colors.primary
                                            : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(labels[level - 1]), \(level) of 5")
                        .accessibilityAddTraits(value.wrappedValue == level ? .isSelected : [])
                    }
                }
            }
        }
    }
}
