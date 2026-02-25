import SwiftUI
import MapKit

struct FullScreenMapView: View {
    let segments: [RouteSegment]
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    var checkpointLocations: [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] = []
    var coloringMode: RouteColoringMode = .pace
    var elevationSegments: [ElevationSegment] = []
    var heartRateSegments: [HeartRateSegment] = []
    var distanceMarkers: [(km: Int, coordinate: (Double, Double))] = []
    var segmentDetails: [SegmentDetail] = []
    var splitPaces: [Int: Double] = [:]
    @Binding var selectedSegment: SegmentDetail?
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredMapStyle") private var mapStyleRaw = MapStylePreference.standard.rawValue

    private var mapStyle: MapStylePreference {
        MapStylePreference(rawValue: mapStyleRaw) ?? .standard
    }

    private var totalDistanceKm: Int {
        segments.last?.kilometerNumber ?? 0
    }

    var filteredMarkers: [(km: Int, coordinate: (Double, Double))] {
        let step: Int
        if !splitPaces.isEmpty {
            step = totalDistanceKm > 10 ? 5 : 1
        } else {
            step = totalDistanceKm > 20 ? 5 : 1
        }
        return distanceMarkers.filter { $0.km % step == 0 }
    }

    var markerAveragePace: Double {
        guard !splitPaces.isEmpty else { return 0 }
        let paces = splitPaces.values.filter { $0 > 0 }
        guard !paces.isEmpty else { return 0 }
        return paces.reduce(0, +) / Double(paces.count)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ZStack(alignment: .topLeading) {
                    MapReader { proxy in
                        Map {
                            routePolylines
                            startFinishMarkers
                            checkpointAnnotations
                            distanceMarkerAnnotations
                            selectedSegmentMarker
                        }
                        .mapStyle(MapStyleResolver.resolve(mapStyle))
                        .mapControls {
                            MapCompass()
                            MapScaleView()
                        }
                        .overlay(alignment: .topTrailing) {
                            MapStyleToggleButton(style: Binding(
                                get: { mapStyle },
                                set: { mapStyleRaw = $0.rawValue }
                            ))
                            .padding(Theme.Spacing.sm)
                        }
                        .onTapGesture { screenPoint in
                            handleTap(at: screenPoint, proxy: proxy)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Full screen route map showing \(segments.count) segments colored by \(coloringMode.rawValue). Tap to view segment details.")
                    }

                    if let detail = selectedSegment {
                        SegmentDetailPopup(detail: detail) {
                            selectedSegment = nil
                        }
                        .padding(Theme.Spacing.sm)
                        .padding(.top, Theme.Spacing.xl)
                    }
                }

                legend
            }
            .navigationTitle("Route Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
