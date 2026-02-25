import SwiftUI

// MARK: - Notifications Section

extension SettingsView {
    @ViewBuilder
    var notificationsSection: some View {
        if let settings = viewModel.appSettings {
            Section("Notifications") {
                Toggle("Training Reminders", isOn: Binding(
                    get: { settings.trainingRemindersEnabled },
                    set: { newValue in
                        Task { await viewModel.updateTrainingReminders(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.trainingRemindersToggle")
                .accessibilityHint("Sends reminders about upcoming training sessions")

                Toggle("Nutrition Reminders", isOn: Binding(
                    get: { settings.nutritionRemindersEnabled },
                    set: { newValue in
                        Task { await viewModel.updateNutritionReminders(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.nutritionRemindersToggle")
                .accessibilityHint("Sends hydration, fuel, and electrolyte reminders during runs")

                if settings.nutritionRemindersEnabled {
                    Toggle("Sound & Haptic Alerts", isOn: Binding(
                        get: { settings.nutritionAlertSoundEnabled },
                        set: { newValue in
                            Task { await viewModel.updateNutritionAlertSound(newValue) }
                        }
                    ))
                    .accessibilityHint("Plays sound and vibration for nutrition reminders")

                    NutritionIntervalPicker(
                        label: "Hydration Interval",
                        valueMinutes: Binding(
                            get: { Int(settings.hydrationIntervalSeconds / 60) },
                            set: { newMin in
                                Task { await viewModel.updateHydrationInterval(TimeInterval(newMin * 60)) }
                            }
                        ),
                        range: Array(stride(from: 10, through: 60, by: 5))
                    )

                    NutritionIntervalPicker(
                        label: "Fuel Interval",
                        valueMinutes: Binding(
                            get: { Int(settings.fuelIntervalSeconds / 60) },
                            set: { newMin in
                                Task { await viewModel.updateFuelInterval(TimeInterval(newMin * 60)) }
                            }
                        ),
                        range: Array(stride(from: 15, through: 90, by: 5))
                    )

                    NutritionIntervalPicker(
                        label: "Electrolyte Interval",
                        valueMinutes: Binding(
                            get: { Int(settings.electrolyteIntervalSeconds / 60) },
                            set: { newMin in
                                Task { await viewModel.updateElectrolyteInterval(TimeInterval(newMin * 60)) }
                            }
                        ),
                        range: Array(stride(from: 15, through: 120, by: 15)),
                        allowOff: true
                    )

                    Toggle("Smart Reminders", isOn: Binding(
                        get: { settings.smartRemindersEnabled },
                        set: { newValue in
                            Task { await viewModel.updateSmartReminders(newValue) }
                        }
                    ))
                    .accessibilityHint("Adjusts reminder timing based on your pace and conditions")
                }

                Toggle("Race Countdown", isOn: Binding(
                    get: { settings.raceCountdownEnabled },
                    set: { newValue in
                        Task { await viewModel.updateRaceCountdown(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.raceCountdownToggle")
                .accessibilityHint("Shows a countdown notification as race day approaches")

                Toggle("Recovery Reminders", isOn: Binding(
                    get: { settings.recoveryRemindersEnabled },
                    set: { newValue in
                        Task { await viewModel.updateRecoveryReminders(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.recoveryRemindersToggle")
                .accessibilityHint("Sends reminders on rest days to stretch and hydrate")

                Toggle("Weekly Summary", isOn: Binding(
                    get: { settings.weeklySummaryEnabled },
                    set: { newValue in
                        Task { await viewModel.updateWeeklySummary(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.weeklySummaryToggle")
                .accessibilityHint("Sends a weekly training summary notification on Sundays")

                Toggle("Quiet Hours", isOn: Binding(
                    get: { settings.quietHoursEnabled },
                    set: { newValue in
                        Task { await viewModel.updateQuietHours(enabled: newValue) }
                    }
                ))
                .accessibilityHint("Suppresses notifications during specified hours")

                if settings.quietHoursEnabled {
                    Picker("Start", selection: Binding(
                        get: { settings.quietHoursStart },
                        set: { hour in
                            Task { await viewModel.updateQuietHoursStart(hour) }
                        }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }

                    Picker("End", selection: Binding(
                        get: { settings.quietHoursEnd },
                        set: { hour in
                            Task { await viewModel.updateQuietHoursEnd(hour) }
                        }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: 0))!
        return formatter.string(from: date)
    }
}
