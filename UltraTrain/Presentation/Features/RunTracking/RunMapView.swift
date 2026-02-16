import SwiftUI
import MapKit

struct RunMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    var showsUserLocation: Bool = true
    var startCoordinate: CLLocationCoordinate2D?
    var endCoordinate: CLLocationCoordinate2D?
    var height: CGFloat = 200

    var body: some View {
        Map {
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Theme.Colors.primary, lineWidth: 3)
            }

            if let start = startCoordinate {
                Annotation("Start", coordinate: start) {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.success)
                        .background(Circle().fill(.white).padding(-1))
                }
            }

            if let end = endCoordinate {
                Annotation("Finish", coordinate: end) {
                    Image(systemName: "flag.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.danger)
                        .background(Circle().fill(.white).padding(-1))
                }
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
