import Foundation

/// Glucose:fructose ratio of a carbohydrate source.
///
/// Research basis: multiple-transportable carbs increase oxidation beyond the
/// single-glucose ceiling (~60 g/hr). A 2:1 glucose:fructose mix raises the
/// ceiling to ~90 g/hr (Jeukendrup). A 1:0.8 ratio is superior for intake
/// >110 g/hr (Rowlands — 74% vs 62% oxidation, less nausea).
enum CarbRatio: String, CaseIterable, Codable, Sendable {
    /// Pure glucose (maltodextrin/dextrose). Ceiling ~60 g/hr.
    case glucoseOnly
    /// 2:1 glucose:fructose — standard multi-transportable. Up to 90 g/hr.
    case twoToOne
    /// 1:0.8 glucose:fructose — preferred for >90 g/hr intake.
    case oneToPointEight

    var displayName: String {
        switch self {
        case .glucoseOnly:     "Glucose only"
        case .twoToOne:        "2:1 glucose:fructose"
        case .oneToPointEight: "1:0.8 glucose:fructose"
        }
    }

    /// Maximum g/hr this ratio supports before GI tolerance breaks down.
    var maxSustainableGramsPerHour: Int {
        switch self {
        case .glucoseOnly:     60
        case .twoToOne:        90
        case .oneToPointEight: 120
        }
    }
}
