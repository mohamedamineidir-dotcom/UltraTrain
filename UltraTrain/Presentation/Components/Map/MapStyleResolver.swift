import MapKit
import SwiftUI

enum MapStyleResolver {
    static func resolve(_ preference: MapStylePreference) -> MapStyle {
        switch preference {
        case .standard: .standard(elevation: .realistic)
        case .satellite: .imagery(elevation: .realistic)
        case .hybrid: .hybrid(elevation: .realistic)
        }
    }
}
