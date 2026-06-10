import Foundation

enum WorkoutTemplateLibrary {

    // MARK: - All Templates

    static let all: [WorkoutTemplate] = trailSpecific + speedWork + hillTraining + recoveryTemplates + racePrep + roadSpecificTemplates

    // MARK: - Trail Specific

    private static let trailSpecific: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "trail_technical_descent", name: String(localized: "wtl.001", defaultValue: "Technical Descent Focus"),
            sessionType: .longRun, targetDistanceKm: 15, targetElevationGainM: 400,
            estimatedDuration: 5400, intensity: .moderate, category: .trailSpecific,
            descriptionText: String(localized: "wtl.002", defaultValue: "Focus on downhill technique on technical single-track. Practice foot placement, quick cadence, and staying relaxed on steep descents."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "trail_night_run", name: String(localized: "wtl.003", defaultValue: "Night Trail Run"),
            sessionType: .longRun, targetDistanceKm: 12, targetElevationGainM: 300,
            estimatedDuration: 4800, intensity: .easy, category: .trailSpecific,
            descriptionText: String(localized: "wtl.004", defaultValue: "Practice running with a headlamp on familiar trails. Build confidence for night sections during ultra races."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "trail_singletrack_agility", name: String(localized: "wtl.005", defaultValue: "Single-Track Agility"),
            sessionType: .intervals, targetDistanceKm: 10, targetElevationGainM: 250,
            estimatedDuration: 3600, intensity: .moderate, category: .trailSpecific,
            descriptionText: String(localized: "wtl.006", defaultValue: "Short bursts on technical terrain with frequent direction changes. Improves proprioception and trail agility."),
            isUserCreated: false
        ),
    ]

    // MARK: - Speed Work

    private static let speedWork: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "speed_fartlek", name: String(localized: "wtl.007", defaultValue: "Trail Fartlek"),
            sessionType: .intervals, targetDistanceKm: 10, targetElevationGainM: 100,
            estimatedDuration: 3000, intensity: .hard, category: .speedWork,
            descriptionText: String(localized: "wtl.008", defaultValue: "Unstructured speed play: alternate fast and easy efforts using terrain as cues. Surge on climbs, recover on flats."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "speed_threshold", name: String(localized: "wtl.009", defaultValue: "Lactate Threshold Run"),
            sessionType: .tempo, targetDistanceKm: 12, targetElevationGainM: 50,
            estimatedDuration: 3600, intensity: .hard, category: .speedWork,
            descriptionText: String(localized: "wtl.010", defaultValue: "Sustained effort at comfortably hard pace (Zone 4). Build the ability to run faster for longer at threshold intensity."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "speed_track_intervals", name: String(localized: "wtl.011", defaultValue: "Track Intervals"),
            sessionType: .intervals, targetDistanceKm: 8, targetElevationGainM: 0,
            estimatedDuration: 2700, intensity: .hard, category: .speedWork,
            descriptionText: String(localized: "wtl.012", defaultValue: "6-8 x 3-minute hard efforts with 2-minute recovery jog. Classic VO2max builder on flat terrain."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "speed_progressive", name: String(localized: "wtl.013", defaultValue: "Progressive Tempo"),
            sessionType: .tempo, targetDistanceKm: 14, targetElevationGainM: 80,
            estimatedDuration: 4200, intensity: .moderate, category: .speedWork,
            descriptionText: String(localized: "wtl.014", defaultValue: "Start easy and gradually increase pace every 3 km until finishing at tempo effort. Teaches pacing discipline."),
            isUserCreated: false
        ),
    ]

    // MARK: - Hill Training

    private static let hillTraining: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "hill_repeats", name: String(localized: "wtl.015", defaultValue: "Hill Repeats"),
            sessionType: .verticalGain, targetDistanceKm: 8, targetElevationGainM: 600,
            estimatedDuration: 3600, intensity: .hard, category: .hillTraining,
            descriptionText: String(localized: "wtl.016", defaultValue: "8-10 x 3-minute uphill hard efforts with jog-down recovery. Build climbing power and muscular endurance."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "hill_power_hike", name: String(localized: "wtl.017", defaultValue: "Power Hiking Session"),
            sessionType: .verticalGain, targetDistanceKm: 6, targetElevationGainM: 800,
            estimatedDuration: 4200, intensity: .moderate, category: .hillTraining,
            descriptionText: String(localized: "wtl.018", defaultValue: "Sustained steep uphill hiking with poles. Practice race-specific power hiking technique at 600-900 m/hr vertical speed."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "hill_staircase", name: String(localized: "wtl.019", defaultValue: "Staircase Session"),
            sessionType: .verticalGain, targetDistanceKm: 5, targetElevationGainM: 500,
            estimatedDuration: 2700, intensity: .hard, category: .hillTraining,
            descriptionText: String(localized: "wtl.020", defaultValue: "Stair climbing repeats for vertical gain. 10 x 50m D+ with walk-down recovery. Great for building leg strength."),
            isUserCreated: false
        ),
    ]

    // MARK: - Recovery

    private static let recoveryTemplates: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "recovery_shakeout", name: String(localized: "wtl.021", defaultValue: "Recovery Shakeout"),
            sessionType: .recovery, targetDistanceKm: 5, targetElevationGainM: 30,
            estimatedDuration: 1800, intensity: .easy, category: .recovery,
            descriptionText: String(localized: "wtl.022", defaultValue: "Very easy, short run to promote blood flow and recovery. Stay in Zone 1-2, conversational pace only."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "recovery_active", name: String(localized: "wtl.023", defaultValue: "Active Recovery"),
            sessionType: .crossTraining, targetDistanceKm: 0, targetElevationGainM: 0,
            estimatedDuration: 2700, intensity: .easy, category: .recovery,
            descriptionText: String(localized: "wtl.024", defaultValue: "Light cross-training: swimming, cycling, or yoga. Keep effort very easy to aid recovery without adding run stress."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "recovery_trail_walk", name: String(localized: "wtl.025", defaultValue: "Trail Walk"),
            sessionType: .recovery, targetDistanceKm: 4, targetElevationGainM: 100,
            estimatedDuration: 2400, intensity: .easy, category: .recovery,
            descriptionText: String(localized: "wtl.026", defaultValue: "Easy hike on trails with light elevation. Active recovery that keeps you moving without running impact."),
            isUserCreated: false
        ),
    ]

    // MARK: - Race Prep

    private static let racePrep: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "raceprep_dress_rehearsal", name: String(localized: "wtl.027", defaultValue: "Dress Rehearsal Run"),
            sessionType: .longRun, targetDistanceKm: 25, targetElevationGainM: 600,
            estimatedDuration: 9000, intensity: .moderate, category: .racePrep,
            descriptionText: String(localized: "wtl.028", defaultValue: "Run in full race kit: vest, poles, nutrition, headlamp. Practice everything you'll use on race day."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "raceprep_nutrition_rehearsal", name: String(localized: "wtl.029", defaultValue: "Nutrition Rehearsal"),
            sessionType: .longRun, targetDistanceKm: 20, targetElevationGainM: 300,
            estimatedDuration: 7200, intensity: .easy, category: .racePrep,
            descriptionText: String(localized: "wtl.030", defaultValue: "Practice your race-day nutrition plan during a long run. Test gels, hydration timing, and stomach tolerance."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "raceprep_course_recon", name: String(localized: "wtl.031", defaultValue: "Course Recon Run"),
            sessionType: .longRun, targetDistanceKm: 15, targetElevationGainM: 400,
            estimatedDuration: 5400, intensity: .easy, category: .racePrep,
            descriptionText: String(localized: "wtl.032", defaultValue: "Run a section of your target race course. Learn the terrain, identify key landmarks, and plan pacing strategy."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "raceprep_race_pace", name: String(localized: "wtl.033", defaultValue: "Race Pace Simulation"),
            sessionType: .tempo, targetDistanceKm: 15, targetElevationGainM: 200,
            estimatedDuration: 4500, intensity: .moderate, category: .racePrep,
            descriptionText: String(localized: "wtl.034", defaultValue: "Run at your target race pace on similar terrain. Build confidence in your pacing strategy."),
            isUserCreated: false
        ),
    ]

    // MARK: - Road Specific

    private static let roadSpecificTemplates: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "road_tempo_run", name: String(localized: "wtl.035", defaultValue: "Road Tempo Run"),
            sessionType: .tempo, targetDistanceKm: 10, targetElevationGainM: 0,
            estimatedDuration: 3000, intensity: .moderate, category: .roadSpecific,
            descriptionText: String(localized: "wtl.036", defaultValue: "Sustained threshold effort on flat terrain. The cornerstone of road race preparation."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "road_vo2max_intervals", name: String(localized: "wtl.037", defaultValue: "Road VO2max Intervals"),
            sessionType: .intervals, targetDistanceKm: 8, targetElevationGainM: 0,
            estimatedDuration: 2700, intensity: .hard, category: .roadSpecific,
            descriptionText: String(localized: "wtl.038", defaultValue: "Track-style VO2max intervals at 5K race pace. Build your aerobic power ceiling."),
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "road_race_pace_long", name: String(localized: "wtl.039", defaultValue: "Race-Pace Long Run"),
            sessionType: .longRun, targetDistanceKm: 25, targetElevationGainM: 0,
            estimatedDuration: 7200, intensity: .moderate, category: .roadSpecific,
            descriptionText: String(localized: "wtl.040", defaultValue: "Long run with embedded blocks at race pace. Race-day simulation for road events."),
            isUserCreated: false
        ),
    ]

    // MARK: - Query

    static func templates(for category: WorkoutCategory) -> [WorkoutTemplate] {
        all.filter { $0.category == category }
    }

    static func search(query: String) -> [WorkoutTemplate] {
        guard !query.isEmpty else { return all }
        let lowered = query.lowercased()
        return all.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.descriptionText.lowercased().contains(lowered)
        }
    }
}
