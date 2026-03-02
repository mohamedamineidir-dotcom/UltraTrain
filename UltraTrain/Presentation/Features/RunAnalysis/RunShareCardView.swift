import SwiftUI
import Charts

struct RunShareCardView: View {
    @ScaledMetric(relativeTo: .title) private var headerTitleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title2) private var headerDateSize: CGFloat = 24
    @ScaledMetric(relativeTo: .largeTitle) private var heroValueSize: CGFloat = 96
    @ScaledMetric(relativeTo: .title3) private var heroLabelSize: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var statValueSize: CGFloat = 28
    @ScaledMetric(relativeTo: .caption) private var statLabelSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var badgeIconSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var badgeTitleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .title2) private var footerIconSize: CGFloat = 24
    @ScaledMetric(relativeTo: .title2) private var footerTextSize: CGFloat = 26

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
                Theme.Colors.shareCardBackgroundTop,
                Theme.Colors.shareCardBackgroundMid,
                Theme.Colors.shareCardBackgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(runTypeLabel)
                .font(.system(size: headerTitleSize, weight: .bold, design: .rounded))
                .tracking(6)
                .foregroundStyle(accentColor.opacity(0.9))

            Text(run.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                .font(.system(size: headerDateSize))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Hero Stats

    private var heroStats: some View {
        HStack(spacing: 64) {
            VStack(spacing: 8) {
                Text(UnitFormatter.formatDistance(run.distanceKm, unit: unitPreference, decimals: 2))
                    .font(.system(size: heroValueSize, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text(UnitFormatter.distanceLabel(unitPreference).uppercased())
                    .font(.system(size: heroLabelSize, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text(RunStatisticsCalculator.formatDuration(run.duration))
                    .font(.system(size: heroValueSize, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text("DURATION")
                    .font(.system(size: heroLabelSize, weight: .medium))
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
                .font(.system(size: statValueSize, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
            Text(label)
                .font(.system(size: statLabelSize, weight: .medium))
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
                        .font(.system(size: badgeIconSize))
                        .foregroundStyle(accentColor)
                    Text(badge.title)
                        .font(.system(size: badgeTitleSize, weight: .semibold))
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
                .font(.system(size: footerIconSize))
                .foregroundStyle(accentColor.opacity(0.7))
            Text("UltraTrain")
                .font(.system(size: footerTextSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Accent

    private var accentColor: Color {
        Theme.Colors.shareCardAccent
    }
}
