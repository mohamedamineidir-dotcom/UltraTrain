import Foundation

enum HeatmapCalculator {

    struct HeatmapCell: Identifiable, Equatable, Sendable {
        let id: Int
        var latitude: Double
        var longitude: Double
        var count: Int
        var normalizedIntensity: Double
    }

    // MARK: - Public

    static func compute(
        tracks: [[TrackPoint]],
        gridSizeMeters: Double = 50
    ) -> [HeatmapCell] {
        guard gridSizeMeters > 0 else { return [] }

        let allPoints = tracks.flatMap { $0 }
        guard !allPoints.isEmpty else { return [] }

        // Find bounding box
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude

        for point in allPoints {
            if point.latitude < minLat { minLat = point.latitude }
            if point.latitude > maxLat { maxLat = point.latitude }
            if point.longitude < minLon { minLon = point.longitude }
            if point.longitude > maxLon { maxLon = point.longitude }
        }

        // Compute grid deltas
        // 1 degree latitude ~ 111,000 meters
        let metersPerDegreeLat: Double = 111_000
        let centerLat = (minLat + maxLat) / 2
        let metersPerDegreeLon = metersPerDegreeLat * cos(centerLat * .pi / 180)

        guard metersPerDegreeLon > 0 else { return [] }

        let latDelta = gridSizeMeters / metersPerDegreeLat
        let lonDelta = gridSizeMeters / metersPerDegreeLon

        guard latDelta > 0, lonDelta > 0 else { return [] }

        // Count points per grid cell using "row,col" key
        var cellCounts: [String: Int] = [:]

        for point in allPoints {
            let row = Int(floor((point.latitude - minLat) / latDelta))
            let col = Int(floor((point.longitude - minLon) / lonDelta))
            let key = "\(row),\(col)"
            cellCounts[key, default: 0] += 1
        }

        guard !cellCounts.isEmpty else { return [] }

        let maxCount = cellCounts.values.max() ?? 1

        // Build cells with center coordinates
        var cells: [HeatmapCell] = []
        cells.reserveCapacity(cellCounts.count)

        var cellId = 0
        for (key, count) in cellCounts {
            let parts = key.split(separator: ",")
            guard parts.count == 2,
                  let row = Int(parts[0]),
                  let col = Int(parts[1]) else { continue }

            let centerLat = minLat + (Double(row) + 0.5) * latDelta
            let centerLon = minLon + (Double(col) + 0.5) * lonDelta
            let normalized = Double(count) / Double(maxCount)

            cells.append(HeatmapCell(
                id: cellId,
                latitude: centerLat,
                longitude: centerLon,
                count: count,
                normalizedIntensity: normalized
            ))

            cellId += 1
        }

        // Sort by id for stable output
        return cells.sorted { $0.id < $1.id }
    }
}
