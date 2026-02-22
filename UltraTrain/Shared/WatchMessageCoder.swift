import Foundation

enum WatchMessageCoder {

    private static let runDataKey = "runData"
    private static let commandKey = "command"
    private static let sessionDataKey = "sessionData"
    private static let completedRunKey = "completedRun"
    private static let complicationKey = "complicationData"
    private static let runHistoryKey = "runHistory"

    // MARK: - Run Data (phone → watch, applicationContext)

    static func encode(_ data: WatchRunData) -> [String: Any] {
        guard let jsonData = try? JSONEncoder().encode(data) else {
            return [:]
        }
        return [runDataKey: jsonData]
    }

    static func decodeRunData(_ context: [String: Any]) -> WatchRunData? {
        guard let jsonData = context[runDataKey] as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(WatchRunData.self, from: jsonData)
    }

    // MARK: - Commands (watch → phone, sendMessage)

    static func encodeCommand(_ command: WatchCommand) -> [String: Any] {
        [commandKey: command.rawValue]
    }

    static func decodeCommand(_ message: [String: Any]) -> WatchCommand? {
        guard let raw = message[commandKey] as? String else {
            return nil
        }
        return WatchCommand(rawValue: raw)
    }

    // MARK: - Session Data (phone → watch, applicationContext)

    static func encodeSessionData(_ data: WatchSessionData) -> [String: Any] {
        guard let jsonData = try? JSONEncoder().encode(data) else {
            return [:]
        }
        return [sessionDataKey: jsonData]
    }

    static func decodeSessionData(_ context: [String: Any]) -> WatchSessionData? {
        guard let jsonData = context[sessionDataKey] as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(WatchSessionData.self, from: jsonData)
    }

    // MARK: - Completed Run (watch → phone, transferUserInfo)

    static func encodeCompletedRun(_ data: WatchCompletedRunData) -> [String: Any] {
        guard let jsonData = try? JSONEncoder().encode(data) else {
            return [:]
        }
        return [completedRunKey: jsonData]
    }

    static func decodeCompletedRun(_ userInfo: [String: Any]) -> WatchCompletedRunData? {
        guard let jsonData = userInfo[completedRunKey] as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(WatchCompletedRunData.self, from: jsonData)
    }

    // MARK: - Complication Data (phone → watch, applicationContext)

    static func encodeComplicationData(_ data: WatchComplicationData) -> [String: Any] {
        guard let jsonData = try? JSONEncoder().encode(data) else {
            return [:]
        }
        return [complicationKey: jsonData]
    }

    static func decodeComplicationData(_ context: [String: Any]) -> WatchComplicationData? {
        guard let jsonData = context[complicationKey] as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(WatchComplicationData.self, from: jsonData)
    }

    // MARK: - Run History (phone → watch, applicationContext)

    static func encodeRunHistory(_ history: [WatchRunHistoryData]) -> Data? {
        try? JSONEncoder().encode(history)
    }

    static func decodeRunHistory(from data: Data) -> [WatchRunHistoryData]? {
        try? JSONDecoder().decode([WatchRunHistoryData].self, from: data)
    }

    static func encodeRunHistoryContext(_ history: [WatchRunHistoryData]) -> [String: Any] {
        guard let jsonData = encodeRunHistory(history) else {
            return [:]
        }
        return [runHistoryKey: jsonData]
    }

    static func decodeRunHistoryContext(_ context: [String: Any]) -> [WatchRunHistoryData]? {
        guard let jsonData = context[runHistoryKey] as? Data else {
            return nil
        }
        return decodeRunHistory(from: jsonData)
    }

    // MARK: - Merge Context

    static func mergeApplicationContext(
        runData: WatchRunData? = nil,
        sessionData: WatchSessionData? = nil,
        complicationData: WatchComplicationData? = nil,
        runHistory: [WatchRunHistoryData]? = nil
    ) -> [String: Any] {
        var context: [String: Any] = [:]
        if let runData {
            context.merge(encode(runData)) { _, new in new }
        }
        if let sessionData {
            context.merge(encodeSessionData(sessionData)) { _, new in new }
        }
        if let complicationData {
            context.merge(encodeComplicationData(complicationData)) { _, new in new }
        }
        if let runHistory {
            context.merge(encodeRunHistoryContext(runHistory)) { _, new in new }
        }
        return context
    }
}
