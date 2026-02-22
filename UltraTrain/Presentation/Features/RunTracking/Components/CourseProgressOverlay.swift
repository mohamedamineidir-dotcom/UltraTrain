import SwiftUI

struct CourseProgressOverlay: View {
    let progress: CourseProgress
    let courseRoute: [TrackPoint]
    let nextCheckpointName: String?
    let nextCheckpointDistanceKm: Double?
    let nextCheckpointETA: TimeInterval?
    let isOffCourse: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isOffCourse {
                offCourseWarning
            }

            HStack(spacing: Theme.Spacing.md) {
                miniElevationProfile
                    .frame(width: 100, height: 40)

                checkpointInfo

                Spacer()

                completionLabel
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.secondaryBackground)
        }
    }

    // MARK: - Off Course Warning

    private var offCourseWarning: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text("Off Course")
                .font(.caption.bold())
            Text("\(Int(progress.distanceOffCourseM))m")
                .font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.danger)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Off course warning. \(Int(progress.distanceOffCourseM)) meters from route"
        )
    }

    // MARK: - Mini Elevation Profile

    private var miniElevationProfile: some View {
        MiniElevationChart(
            courseRoute: courseRoute,
            percentComplete: progress.percentComplete
        )
    }

    // MARK: - Checkpoint Info

    @ViewBuilder
    private var checkpointInfo: some View {
        if let name = nextCheckpointName {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.label)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.xs) {
                    if let dist = nextCheckpointDistanceKm {
                        Text(String(format: "%.1f km", dist))
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    if let eta = nextCheckpointETA {
                        Text(formattedETA(eta))
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(checkpointAccessibilityLabel)
        }
    }

    // MARK: - Completion Label

    private var completionLabel: some View {
        Text(String(format: "%.0f%%", progress.percentComplete))
            .font(.caption.bold())
            .foregroundStyle(Theme.Colors.primary)
            .accessibilityLabel(
                "\(Int(progress.percentComplete)) percent complete"
            )
    }

    // MARK: - Helpers

    private func formattedETA(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return String(format: "~%dh%02d", hours, minutes)
        }
        return String(format: "~%dmin", minutes)
    }

    private var checkpointAccessibilityLabel: String {
        var parts: [String] = []
        if let name = nextCheckpointName {
            parts.append("Next checkpoint: \(name)")
        }
        if let dist = nextCheckpointDistanceKm {
            parts.append(String(format: "%.1f kilometers away", dist))
        }
        if let eta = nextCheckpointETA {
            parts.append("estimated \(formattedETA(eta))")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Mini Elevation Chart

private struct MiniElevationChart: View {
    let courseRoute: [TrackPoint]
    let percentComplete: Double

    var body: some View {
        GeometryReader { geo in
            let sampled = sampledAltitudes(width: geo.size.width)
            let normalized = normalizeAltitudes(sampled, height: geo.size.height)

            ZStack(alignment: .leading) {
                elevationPath(points: normalized, size: geo.size)
                    .stroke(
                        Theme.Colors.secondaryLabel.opacity(0.4),
                        lineWidth: 1.5
                    )

                let completedWidth = geo.size.width * (percentComplete / 100.0)

                elevationPath(points: normalized, size: geo.size)
                    .stroke(Theme.Colors.primary, lineWidth: 1.5)
                    .clipShape(
                        Rectangle()
                            .size(
                                width: completedWidth,
                                height: geo.size.height
                            )
                    )

                positionMarker(
                    points: normalized,
                    size: geo.size,
                    completedWidth: completedWidth
                )
            }
        }
        .accessibilityHidden(true)
    }

    private func sampledAltitudes(width: CGFloat) -> [Double] {
        let maxSamples = max(Int(width / 2), 20)
        guard courseRoute.count >= 2 else { return [] }

        if courseRoute.count <= maxSamples {
            return courseRoute.map(\.altitudeM)
        }

        let step = Double(courseRoute.count - 1) / Double(maxSamples - 1)
        return (0..<maxSamples).map { i in
            let idx = min(Int(Double(i) * step), courseRoute.count - 1)
            return courseRoute[idx].altitudeM
        }
    }

    private func normalizeAltitudes(
        _ altitudes: [Double], height: CGFloat
    ) -> [CGFloat] {
        guard let minAlt = altitudes.min(),
              let maxAlt = altitudes.max(),
              maxAlt > minAlt
        else {
            return altitudes.map { _ in height / 2 }
        }

        let range = maxAlt - minAlt
        let padding = height * 0.1
        let usable = height - 2 * padding

        return altitudes.map { alt in
            let normalized = (alt - minAlt) / range
            return height - padding - (normalized * usable)
        }
    }

    private func elevationPath(
        points: [CGFloat], size: CGSize
    ) -> Path {
        Path { path in
            guard points.count >= 2 else { return }
            let stepX = size.width / CGFloat(points.count - 1)

            path.move(to: CGPoint(x: 0, y: points[0]))
            for i in 1..<points.count {
                path.addLine(
                    to: CGPoint(x: CGFloat(i) * stepX, y: points[i])
                )
            }
        }
    }

    private func positionMarker(
        points: [CGFloat],
        size: CGSize,
        completedWidth: CGFloat
    ) -> some View {
        let idx = markerIndex(points: points, size: size, x: completedWidth)
        let y = idx < points.count ? points[idx] : size.height / 2

        return Circle()
            .fill(Theme.Colors.primary)
            .frame(width: 6, height: 6)
            .position(x: completedWidth, y: y)
    }

    private func markerIndex(
        points: [CGFloat], size: CGSize, x: CGFloat
    ) -> Int {
        guard points.count >= 2 else { return 0 }
        let stepX = size.width / CGFloat(points.count - 1)
        let index = Int(x / stepX)
        return min(max(index, 0), points.count - 1)
    }
}
