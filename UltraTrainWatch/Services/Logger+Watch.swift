import Foundation
import os

extension Logger {
    private static let subsystem = "com.ultratrain.app.watchkitapp"

    static let watch = Logger(subsystem: subsystem, category: "watch")
}
