import Foundation

enum RaceEndpoints {
    static let racesPath = "/races"

    static func racePath(id: String) -> String {
        "/races/\(id)"
    }
}
