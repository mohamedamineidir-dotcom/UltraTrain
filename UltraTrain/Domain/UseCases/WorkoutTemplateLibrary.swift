import Foundation

enum WorkoutTemplateLibrary {

    // MARK: - All Templates

    static let all: [WorkoutTemplate] = trailSpecific + speedWork + hillTraining + recoveryTemplates + racePrep

    // MARK: - Trail Specific

    private static let trailSpecific: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "trail_technical_descent", name: "Technical Descent Focus",
            sessionType: .longRun, targetDistanceKm: 15, targetElevationGainM: 400,
            estimatedDuration: 5400, intensity: .moderate, category: .trailSpecific,
            descriptionText: "Focus on downhill technique on technical single-track. Practice foot placement, quick cadence, and staying relaxed on steep descents.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "trail_night_run", name: "Night Trail Run",
            sessionType: .longRun, targetDistanceKm: 12, targetElevationGainM: 300,
            estimatedDuration: 4800, intensity: .easy, category: .trailSpecific,
            descriptionText: "Practice running with a headlamp on familiar trails. Build confidence for night sections during ultra races.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "trail_singletrack_agility", name: "Single-Track Agility",
            sessionType: .intervals, targetDistanceKm: 10, targetElevationGainM: 250,
            estimatedDuration: 3600, intensity: .moderate, category: .trailSpecific,
            descriptionText: "Short bursts on technical terrain with frequent direction changes. Improves proprioception and trail agility.",
            isUserCreated: false
        ),
    ]

    // MARK: - Speed Work

    private static let speedWork: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "speed_fartlek", name: "Trail Fartlek",
            sessionType: .intervals, targetDistanceKm: 10, targetElevationGainM: 100,
            estimatedDuration: 3000, intensity: .hard, category: .speedWork,
            descriptionText: "Unstructured speed play: alternate fast and easy efforts using terrain as cues. Surge on climbs, recover on flats.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "speed_threshold", name: "Lactate Threshold Run",
            sessionType: .tempo, targetDistanceKm: 12, targetElevationGainM: 50,
            estimatedDuration: 3600, intensity: .hard, category: .speedWork,
            descriptionText: "Sustained effort at comfortably hard pace (Zone 4). Build the ability to run faster for longer at threshold intensity.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "speed_track_intervals", name: "Track Intervals",
            sessionType: .intervals, targetDistanceKm: 8, targetElevationGainM: 0,
            estimatedDuration: 2700, intensity: .hard, category: .speedWork,
            descriptionText: "6-8 x 3-minute hard efforts with 2-minute recovery jog. Classic VO2max builder on flat terrain.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "speed_progressive", name: "Progressive Tempo",
            sessionType: .tempo, targetDistanceKm: 14, targetElevationGainM: 80,
            estimatedDuration: 4200, intensity: .moderate, category: .speedWork,
            descriptionText: "Start easy and gradually increase pace every 3 km until finishing at tempo effort. Teaches pacing discipline.",
            isUserCreated: false
        ),
    ]

    // MARK: - Hill Training

    private static let hillTraining: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "hill_repeats", name: "Hill Repeats",
            sessionType: .verticalGain, targetDistanceKm: 8, targetElevationGainM: 600,
            estimatedDuration: 3600, intensity: .hard, category: .hillTraining,
            descriptionText: "8-10 x 3-minute uphill hard efforts with jog-down recovery. Build climbing power and muscular endurance.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "hill_power_hike", name: "Power Hiking Session",
            sessionType: .verticalGain, targetDistanceKm: 6, targetElevationGainM: 800,
            estimatedDuration: 4200, intensity: .moderate, category: .hillTraining,
            descriptionText: "Sustained steep uphill hiking with poles. Practice race-specific power hiking technique at 600-900 m/hr vertical speed.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "hill_staircase", name: "Staircase Session",
            sessionType: .verticalGain, targetDistanceKm: 5, targetElevationGainM: 500,
            estimatedDuration: 2700, intensity: .hard, category: .hillTraining,
            descriptionText: "Stair climbing repeats for vertical gain. 10 x 50m D+ with walk-down recovery. Great for building leg strength.",
            isUserCreated: false
        ),
    ]

    // MARK: - Recovery

    private static let recoveryTemplates: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "recovery_shakeout", name: "Recovery Shakeout",
            sessionType: .recovery, targetDistanceKm: 5, targetElevationGainM: 30,
            estimatedDuration: 1800, intensity: .easy, category: .recovery,
            descriptionText: "Very easy, short run to promote blood flow and recovery. Stay in Zone 1-2, conversational pace only.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "recovery_active", name: "Active Recovery",
            sessionType: .crossTraining, targetDistanceKm: 0, targetElevationGainM: 0,
            estimatedDuration: 2700, intensity: .easy, category: .recovery,
            descriptionText: "Light cross-training: swimming, cycling, or yoga. Keep effort very easy to aid recovery without adding run stress.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "recovery_trail_walk", name: "Trail Walk",
            sessionType: .recovery, targetDistanceKm: 4, targetElevationGainM: 100,
            estimatedDuration: 2400, intensity: .easy, category: .recovery,
            descriptionText: "Easy hike on trails with light elevation. Active recovery that keeps you moving without running impact.",
            isUserCreated: false
        ),
    ]

    // MARK: - Race Prep

    private static let racePrep: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "raceprep_dress_rehearsal", name: "Dress Rehearsal Run",
            sessionType: .longRun, targetDistanceKm: 25, targetElevationGainM: 600,
            estimatedDuration: 9000, intensity: .moderate, category: .racePrep,
            descriptionText: "Run in full race kit: vest, poles, nutrition, headlamp. Practice everything you'll use on race day.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "raceprep_nutrition_rehearsal", name: "Nutrition Rehearsal",
            sessionType: .longRun, targetDistanceKm: 20, targetElevationGainM: 300,
            estimatedDuration: 7200, intensity: .easy, category: .racePrep,
            descriptionText: "Practice your race-day nutrition plan during a long run. Test gels, hydration timing, and stomach tolerance.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "raceprep_course_recon", name: "Course Recon Run",
            sessionType: .longRun, targetDistanceKm: 15, targetElevationGainM: 400,
            estimatedDuration: 5400, intensity: .easy, category: .racePrep,
            descriptionText: "Run a section of your target race course. Learn the terrain, identify key landmarks, and plan pacing strategy.",
            isUserCreated: false
        ),
        WorkoutTemplate(
            id: "raceprep_race_pace", name: "Race Pace Simulation",
            sessionType: .tempo, targetDistanceKm: 15, targetElevationGainM: 200,
            estimatedDuration: 4500, intensity: .moderate, category: .racePrep,
            descriptionText: "Run at your target race pace on similar terrain. Build confidence in your pacing strategy.",
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
