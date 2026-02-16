import SwiftUI
import MapKit

struct RouteMapView: View {
    let segments: [RouteSegment]
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    var height: CGFloat = 250

    var body: some View {
        Map {
            ForEach(segments) { segment in
                if segment.coordinates.count >= 2 {
                    MapPolyline(coordinates: segment.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1)
                    })
                    .stroke(paceColor(for: segment), lineWidth: 4)
                }
            }

            if let start = startCoordinate {
                Annotation("Start", coordinate: start) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.success)
                        .background(Circle().fill(.white).padding(-2))
                }
            }

            if let end = endCoordinate {
                Annotation("Finish", coordinate: end) {
                    Image(systemName: "flag.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.danger)
                        .background(Circle().fill(.white).padding(-2))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }

    // MARK: - Pace Color

    private var averagePace: Double {
        let paces = segments.map(\.paceSecondsPerKm).filter { $0 > 0 }
        guard !paces.isEmpty else { return 0 }
        return paces.reduce(0, +) / Double(paces.count)
    }

    private func paceColor(for segment: RouteSegment) -> Color {
        guard averagePace > 0 else { return Theme.Colors.primary }
        let ratio = segment.paceSecondsPerKm / averagePace
        if ratio < 0.9 { return Theme.Colors.success }
        if ratio <= 1.1 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }
}
