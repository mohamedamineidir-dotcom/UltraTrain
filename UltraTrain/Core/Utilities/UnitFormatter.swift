import Foundation

enum UnitFormatter {

    // MARK: - Conversion Constants

    private static let kmPerMile = 1.60934
    private static let feetPerMeter = 3.28084
    private static let lbsPerKg = 2.20462
    private static let cmPerInch = 2.54

    // MARK: - Format with Unit Label

    static func formatDistance(_ km: Double, unit: UnitPreference, decimals: Int = 1) -> String {
        let value = distanceValue(km, unit: unit)
        let format = "%.\(decimals)f \(distanceLabel(unit))"
        return String(format: format, value)
    }

    static func formatElevation(_ meters: Double, unit: UnitPreference) -> String {
        let value = elevationValue(meters, unit: unit)
        return String(format: "%.0f \(elevationShortLabel(unit))", value)
    }

    static func formatWeight(_ kg: Double, unit: UnitPreference, decimals: Int = 1) -> String {
        let value = weightValue(kg, unit: unit)
        return String(format: "%.\(decimals)f \(weightLabel(unit))", value)
    }

    static func formatHeight(_ cm: Double, unit: UnitPreference) -> String {
        switch unit {
        case .metric:
            return String(format: "%.0f cm", cm)
        case .imperial:
            let totalInches = Int((cm / cmPerInch).rounded())
            let feet = totalInches / 12
            let inches = totalInches % 12
            return "\(feet)'\(inches)\""
        }
    }

    static func formatPace(_ secondsPerKm: Double, unit: UnitPreference) -> String {
        let converted = paceValue(secondsPerKm, unit: unit)
        guard converted > 0, converted.isFinite else { return "--:--" }
        let minutes = Int(converted) / 60
        let seconds = Int(converted) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Unit Labels

    static func distanceLabel(_ unit: UnitPreference) -> String {
        unit == .metric ? "km" : "mi"
    }

    static func elevationLabel(_ unit: UnitPreference) -> String {
        unit == .metric ? "m D+" : "ft D+"
    }

    static func elevationShortLabel(_ unit: UnitPreference) -> String {
        unit == .metric ? "m" : "ft"
    }

    static func paceLabel(_ unit: UnitPreference) -> String {
        unit == .metric ? "/km" : "/mi"
    }

    static func weightLabel(_ unit: UnitPreference) -> String {
        unit == .metric ? "kg" : "lb"
    }

    // MARK: - Value Conversion (metric → display)

    static func distanceValue(_ km: Double, unit: UnitPreference) -> Double {
        unit == .metric ? km : km / kmPerMile
    }

    static func elevationValue(_ meters: Double, unit: UnitPreference) -> Double {
        unit == .metric ? meters : meters * feetPerMeter
    }

    static func weightValue(_ kg: Double, unit: UnitPreference) -> Double {
        unit == .metric ? kg : kg * lbsPerKg
    }

    static func paceValue(_ secondsPerKm: Double, unit: UnitPreference) -> Double {
        unit == .metric ? secondsPerKm : secondsPerKm * kmPerMile
    }

    // MARK: - Reverse Conversion (display → metric for storage)

    static func distanceToKm(_ value: Double, unit: UnitPreference) -> Double {
        unit == .metric ? value : value * kmPerMile
    }

    static func elevationToMeters(_ value: Double, unit: UnitPreference) -> Double {
        unit == .metric ? value : value / feetPerMeter
    }

    static func weightToKg(_ value: Double, unit: UnitPreference) -> Double {
        unit == .metric ? value : value / lbsPerKg
    }
}
