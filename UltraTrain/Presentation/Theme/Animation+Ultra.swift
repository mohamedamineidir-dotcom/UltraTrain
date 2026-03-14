import SwiftUI

extension Animation {
    static let ultraSpring = Animation.spring(duration: 0.35, bounce: 0.2)
    static let ultraEaseOut = Animation.easeOut(duration: 0.25)
    static let ultraStagger = Animation.spring(duration: 0.5, bounce: 0.15)
    static let pulseGlow = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
}
