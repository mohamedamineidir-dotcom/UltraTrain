import SwiftUI
import Charts

struct RunShareCardView: View {
    let run: CompletedRun
    let elevationProfile: [ElevationProfilePoint]
    let advancedMetrics: AdvancedRunMetrics?
    let badges: [ImprovementBadge]
    let unitPreference: UnitPreference

    private var runTypeLabel: String {
        if run.distanceKm >= 42 { return "ULTRA RUN" }
        if run.distanceKm >= 10 { return "TRAIL RUN" }
        return "RUN"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            headerSection
            Spacer().frame(height: 48)
            heroStats
            Spacer().frame(height: 32)
            secondaryStats
            Spacer().frame(height: 40)
            elevationSection
            if !badges.isEmpty {
                Spacer().frame(height: 32)
                badgesSection
            }
            Spacer()
            footerSection
            Spacer().frame(height: 60)
        }
        .frame(width: 1080, height: 1350)
        .background(backgroundGradient)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.08, blue: 0.14),
                Color(red: 0.04, green: 0.12, blue: 0.18),
                Color(red: 0.06, green: 0.06, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(runTypeLabel)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(6)
                .foregroundStyle(accentColor.opacity(0.9))

            Text(run.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Hero Stats

    private var heroStats: some View {
        HStack(spacing: 64) {
            VStack(spacing: 8) {
                Text(UnitFormatter.formatDistance(run.distanceKm, unit: unitPreference, decimals: 2))
                    .font(.system(size: 96, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text(UnitFormatter.distanceLabel(unitPreference).uppercased())
                    .font(.system(size: 22, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text(RunStatisticsCalculator.formatDuration(run.duration))
                    .font(.system(size: 96, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text("DURATION")
                    .font(.system(size: 22, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Secondary Stats

    private var secondaryStats: some View {
        HStack(spacing: 0) {
            statPill(
                label: "AVG PACE",
                value: RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: unitPreference)
                    + " " + UnitFormatter.paceLabel(unitPreference)
            )
            statDivider
            statPill(
                label: "ELEVATION",
                value: "+\(UnitFormatter.formatElevation(run.elevationGainM, unit: unitPreference)) / -\(UnitFormatter.formatElevation(run.elevationLossM, unit: unitPreference))"
            )
            if let hr = run.averageHeartRate {
                statDivider
                statPill(label: "AVG HR", value: "\(hr) bpm")
            }
        }
        .padding(.horizontal, 60)
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.15))
            .frame(width: 1, height: 50)
    }

    // MARK: - Elevation

    private var elevationSection: some View {
        VStack(spacing: 0) {
            if !elevationProfile.isEmpty {
                Chart {
                    ForEach(elevationProfile) { point in
                        AreaMark(
                            x: .value("D", point.distanceKm),
                            y: .value("A", point.altitudeM)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [accentColor.opacity(0.4), accentColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("D", point.distanceKm),
                            y: .value("A", point.altitudeM)
                        )
                        .foregroundStyle(accentColor.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 200)
                .padding(.horizontal, 60)
            }
        }
    }

    // MARK: - Badges

    private var badgesSection: some View {
        HStack(spacing: 16) {
            ForEach(badges.prefix(3)) { badge in
                HStack(spacing: 8) {
                    Image(systemName: badge.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                    Text(badge.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.08))
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 24))
                .foregroundStyle(accentColor.opacity(0.7))
            Text("UltraTrain")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Accent

    private var accentColor: Color {
        Color(red: 0.3, green: 0.75, blue: 0.55)
    }
}
