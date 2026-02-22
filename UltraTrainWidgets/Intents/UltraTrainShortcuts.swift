import AppIntents

struct UltraTrainShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRunIntent(),
            phrases: ["Start my run in \(.applicationName)",
                      "Start a training run with \(.applicationName)"],
            shortTitle: "Start Run",
            systemImageName: "figure.run"
        )
        AppShortcut(
            intent: ShowNextSessionIntent(),
            phrases: ["What's my next session in \(.applicationName)",
                      "Next training session in \(.applicationName)"],
            shortTitle: "Next Session",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: ShowRaceCountdownIntent(),
            phrases: ["How many days until my race in \(.applicationName)",
                      "Race countdown in \(.applicationName)"],
            shortTitle: "Race Countdown",
            systemImageName: "flag.checkered"
        )
        AppShortcut(
            intent: ShowFitnessIntent(),
            phrases: ["What's my fitness in \(.applicationName)",
                      "Show fitness status in \(.applicationName)"],
            shortTitle: "Fitness Status",
            systemImageName: "heart.fill"
        )
        AppShortcut(
            intent: ShowTrainingPlanIntent(),
            phrases: ["Show my training plan in \(.applicationName)"],
            shortTitle: "Training Plan",
            systemImageName: "list.bullet.clipboard"
        )
        AppShortcut(
            intent: ShowWeeklyProgressIntent(),
            phrases: ["How's my training week in \(.applicationName)"],
            shortTitle: "Weekly Progress",
            systemImageName: "chart.bar.fill"
        )
        AppShortcut(
            intent: MarkSessionCompleteIntent(),
            phrases: ["Mark session complete in \(.applicationName)"],
            shortTitle: "Complete Session",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: SkipSessionIntent(),
            phrases: ["Skip my session in \(.applicationName)"],
            shortTitle: "Skip Session",
            systemImageName: "forward.fill"
        )
    }
}
