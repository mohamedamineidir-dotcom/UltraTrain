import SwiftUI
import MapKit

struct RunMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    var showsUserLocation: Bool = true
    var height: CGFloat = 200

    var body: some View {
        Map {
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Theme.Colors.primary, lineWidth: 3)
            }
            if showsUserLocation {
                UserAnnotation()
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}
