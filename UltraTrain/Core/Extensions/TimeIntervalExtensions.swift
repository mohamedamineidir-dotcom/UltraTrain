import Foundation

extension TimeInterval {
    var hoursMinutesSeconds: (hours: Int, minutes: Int, seconds: Int) {
        let total = Int(self)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return (hours, minutes, seconds)
    }

    var formattedDuration: String {
        let hms = hoursMinutesSeconds
        if hms.hours > 0 {
            return String(format: "%dh%02dm%02ds", hms.hours, hms.minutes, hms.seconds)
        }
        return String(format: "%dm%02ds", hms.minutes, hms.seconds)
    }

    var formattedPace: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}
