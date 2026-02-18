import SwiftUI
import WidgetKit

@main
struct UltraTrainWatchWidgets: WidgetBundle {
    var body: some Widget {
        WatchNextSessionComplication()
        WatchRaceCountdownComplication()
    }
}
