import Foundation

extension Double {
    func rounded(to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }

    var kmFormatted: String {
        String(format: "%.1f km", self)
    }

    var elevationFormatted: String {
        String(format: "%.0f m", self)
    }
}
