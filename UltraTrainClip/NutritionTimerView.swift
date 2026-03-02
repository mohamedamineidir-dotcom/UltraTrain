import SwiftUI
import StoreKit

struct NutritionTimerView: View {
    let raceId: String?
    @State private var viewModel = NutritionTimerViewModel()
    @State private var showOverlay = false

    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.error {
                    errorView(error)
                } else if viewModel.nutritionPlan != nil {
                    timerContent
                } else {
                    ProgressView("Loading nutrition plan...")
                }
            }
            .navigationTitle(viewModel.nutritionPlan?.raceName ?? "Nutrition Timer")
            .navigationBarTitleDisplayMode(.inline)
            .task { viewModel.load(raceId: raceId) }
            .appStoreOverlay(isPresented: $showOverlay) {
                SKOverlay.AppClipConfiguration(position: .bottom)
            }
        }
    }

    // MARK: - Timer Content

    private var timerContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                timerDisplay
                nextReminderCard
                controlButtons
                reminderList
            }
            .padding()
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(formattedTime)
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(viewModel.isRunning ? .primary : .secondary)

            if let plan = viewModel.nutritionPlan {
                HStack(spacing: 16) {
                    Label("\(plan.caloriesPerHour) cal/hr", systemImage: "bolt.fill")
                    Label("\(plan.hydrationMlPerHour) ml/hr", systemImage: "drop.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Next Reminder

    @ViewBuilder
    private var nextReminderCard: some View {
        if let active = viewModel.activeReminder, active.isTriggered {
            VStack(spacing: 12) {
                Image(systemName: active.type.icon)
                    .font(.title)
                    .foregroundStyle(.orange)
                Text(active.message)
                    .font(.headline)
                Button("Done") {
                    viewModel.dismissReminder(active)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if let next = viewModel.reminders.first(where: { !$0.isDismissed && !$0.isTriggered && $0.triggerTimeSeconds > viewModel.elapsedSeconds }) {
            HStack {
                Image(systemName: next.type.icon)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text("Next: \(next.message)")
                        .font(.subheadline)
                    Text("in \(timeUntil(next.triggerTimeSeconds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 24) {
            if viewModel.isRunning {
                Button {
                    viewModel.stopTimer()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            } else {
                Button {
                    viewModel.startTimer()
                } label: {
                    Label(viewModel.elapsedSeconds > 0 ? "Resume" : "Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if viewModel.elapsedSeconds > 0 && !viewModel.isRunning {
                Button {
                    viewModel.resetTimer()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Reminder List

    private var reminderList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Reminders")
                .font(.headline)
                .padding(.top, 8)

            let upcoming = viewModel.reminders.filter { !$0.isDismissed && $0.triggerTimeSeconds > viewModel.elapsedSeconds }
                .prefix(8)

            ForEach(Array(upcoming)) { reminder in
                NutritionReminderRow(reminder: reminder, elapsedSeconds: viewModel.elapsedSeconds)
            }

            if upcoming.isEmpty && viewModel.elapsedSeconds > 0 {
                Text("No more reminders scheduled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 16)

            Button("Get the full UltraTrain app") {
                showOverlay = true
            }
            .font(.footnote)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let hours = Int(viewModel.elapsedSeconds) / 3600
        let minutes = (Int(viewModel.elapsedSeconds) % 3600) / 60
        let seconds = Int(viewModel.elapsedSeconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func timeUntil(_ targetSeconds: TimeInterval) -> String {
        let remaining = max(0, Int(targetSeconds - viewModel.elapsedSeconds))
        let min = remaining / 60
        let sec = remaining % 60
        return min > 0 ? "\(min)m \(sec)s" : "\(sec)s"
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Get UltraTrain") {
                showOverlay = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
