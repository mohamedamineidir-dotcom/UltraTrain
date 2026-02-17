import Foundation

enum WatchMessageCoder {

    private static let runDataKey = "runData"
    private static let commandKey = "command"

    // MARK: - Run Data

    static func encode(_ data: WatchRunData) -> [String: Any] {
        guard let jsonData = try? JSONEncoder().encode(data) else {
            return [:]
        }
        return [runDataKey: jsonData]
    }

    static func decode(_ context: [String: Any]) -> WatchRunData? {
        guard let jsonData = context[runDataKey] as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(WatchRunData.self, from: jsonData)
    }

    // MARK: - Commands

    static func encodeCommand(_ command: WatchCommand) -> [String: Any] {
        [commandKey: command.rawValue]
    }

    static func decodeCommand(_ message: [String: Any]) -> WatchCommand? {
        guard let raw = message[commandKey] as? String else {
            return nil
        }
        return WatchCommand(rawValue: raw)
    }
}
