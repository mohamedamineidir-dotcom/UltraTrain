import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.ultratrain.app"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let training = Logger(subsystem: subsystem, category: "training")
    static let tracking = Logger(subsystem: subsystem, category: "tracking")
    static let nutrition = Logger(subsystem: subsystem, category: "nutrition")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let fitness = Logger(subsystem: subsystem, category: "fitness")
    static let settings = Logger(subsystem: subsystem, category: "settings")
    static let healthKit = Logger(subsystem: subsystem, category: "healthKit")
}
