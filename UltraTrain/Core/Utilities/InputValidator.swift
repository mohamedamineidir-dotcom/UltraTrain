import Foundation
import os

enum InputValidator {

    // MARK: - GPS Validation

    static func isValidLatitude(_ lat: Double) -> Bool {
        lat >= -90 && lat <= 90 && !lat.isNaN && !lat.isInfinite
    }

    static func isValidLongitude(_ lon: Double) -> Bool {
        lon >= -180 && lon <= 180 && !lon.isNaN && !lon.isInfinite
    }

    static func isValidAltitude(_ alt: Double) -> Bool {
        alt >= -500 && alt <= 9000 && !alt.isNaN && !alt.isInfinite
    }

    static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        isValidLatitude(latitude) && isValidLongitude(longitude)
    }

    // MARK: - Heart Rate Validation

    static func isValidHeartRate(_ hr: Int) -> Bool {
        hr >= 20 && hr <= 250
    }

    static func isValidOptionalHeartRate(_ hr: Int?) -> Bool {
        guard let hr else { return true }
        return isValidHeartRate(hr)
    }

    // MARK: - Pace Validation

    static func isValidPace(_ secondsPerKm: Double) -> Bool {
        secondsPerKm >= 60 && secondsPerKm <= 3600 && !secondsPerKm.isNaN && !secondsPerKm.isInfinite
    }

    static func isValidOptionalPace(_ secondsPerKm: Double?) -> Bool {
        guard let secondsPerKm else { return true }
        return isValidPace(secondsPerKm)
    }

    // MARK: - Distance Validation

    static func isValidDistance(_ km: Double) -> Bool {
        km >= 0 && km <= 1000 && !km.isNaN && !km.isInfinite
    }

    // MARK: - Elevation Validation

    static func isValidElevation(_ meters: Double) -> Bool {
        meters >= 0 && meters <= 50000 && !meters.isNaN && !meters.isInfinite
    }

    // MARK: - Duration Validation

    static func isValidDuration(_ seconds: TimeInterval) -> Bool {
        seconds >= 0 && seconds <= 604_800 && !seconds.isNaN && !seconds.isInfinite
    }

    // MARK: - Body Metrics Validation

    static func isValidWeight(_ kg: Double) -> Bool {
        kg >= 20 && kg <= 300 && !kg.isNaN && !kg.isInfinite
    }

    static func isValidHeight(_ cm: Double) -> Bool {
        cm >= 50 && cm <= 300 && !cm.isNaN && !cm.isInfinite
    }

    // MARK: - Text Sanitization

    static func sanitizeText(_ text: String, maxLength: Int = 500) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.unicodeScalars.filter { scalar in
            !CharacterSet.controlCharacters.contains(scalar) || scalar == "\n" || scalar == "\t"
        }
        let result = String(String.UnicodeScalarView(cleaned))
        if result.count > maxLength {
            return String(result.prefix(maxLength))
        }
        return result
    }

    static func sanitizeOptionalText(_ text: String?, maxLength: Int = 500) -> String? {
        guard let text else { return nil }
        let result = sanitizeText(text, maxLength: maxLength)
        return result.isEmpty ? nil : result
    }

    static func sanitizeName(_ name: String) -> String {
        sanitizeText(name, maxLength: 100)
    }

    // MARK: - Positive Value Validation

    static func isPositive(_ value: Double) -> Bool {
        value > 0 && !value.isNaN && !value.isInfinite
    }
}
