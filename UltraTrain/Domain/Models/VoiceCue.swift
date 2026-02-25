import Foundation

struct VoiceCue: Equatable, Sendable {
    let type: VoiceCueType
    let message: String
    let priority: VoiceCuePriority
}
