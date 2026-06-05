import Foundation
import Testing
@testable import UltraTrain

@Suite("Interval session composer")
struct IntervalComposerDiagnostic {

    @Test("No two quality work parts repeat in a marathon plan")
    func noRepeatsWithinPlan() {
        let seq = sequence(volumeKm: 79, experience: .advanced, pb: 2100)
        let recIdx = Set(seq.names.indices.filter {
            seq.names[$0].contains("strides") || seq.names[$0].contains("primer")
        })
        let sigs = seq.signatures.indices.filter { !recIdx.contains($0) }.map { seq.signatures[$0] }
        #expect(sigs.count >= 20)
        #expect(Set(sigs).count == sigs.count, "Duplicate quality work part in plan")
    }

    @Test("Different athlete profiles get different sessions")
    func profileDependence() {
        let adv = sequence(volumeKm: 79, experience: .advanced, pb: 2100)
        let int = sequence(volumeKm: 50, experience: .intermediate, pb: 2580)
        #expect(adv.names != int.names)
    }

    @Test("Work volume progressively overloads with the session ordinal")
    func progressiveOverload() {
        func budget(_ ord: Int) -> Double {
            IntervalSessionComposer.workBudgetMinutes(.init(
                category: .threshold, phase: .build, discipline: .roadMarathon,
                experience: .advanced, weeklyVolumeKm: 79, paceProfile: nil,
                ordinal: ord, slotIndex: 1, isRecoveryWeek: false,
                isFirstTimer: false, athleteAge: 32))
        }
        #expect(budget(0) < budget(3))
        #expect(budget(3) < budget(6))
    }

    private func profile(pbSeconds: TimeInterval, experience: ExperienceLevel) -> RoadPaceProfile {
        RoadPaceCalculator.paceProfile(
            goalTime: nil, raceDistanceKm: 42.195,
            personalBests: [PersonalBest(id: UUID(), distance: .tenK, timeSeconds: pbSeconds, date: .now)],
            vmaKmh: nil, experience: experience
        )
    }

    /// Marathon phase layout for an advanced 21-week plan: base6/build6/peak6,
    /// recovery on weeks 4/8/12/16 (matches the generator's cadence).
    private let layout: [(phase: TrainingPhase, weekInPhase: Int, recovery: Bool)] = {
        var out: [(TrainingPhase, Int, Bool)] = []
        let phases: [(TrainingPhase, Int)] = [(.base, 6), (.build, 6), (.peak, 6)]
        var globalWeek = 0
        for (ph, n) in phases {
            for w in 0..<n {
                globalWeek += 1
                let rec = [4, 8, 12, 16].contains(globalWeek)
                out.append((ph, w, rec))
            }
        }
        return out
    }()

    private func sequence(volumeKm: Double, experience: ExperienceLevel, pb: TimeInterval)
        -> (names: [String], signatures: [String]) {
        let prof = profile(pbSeconds: pb, experience: experience)
        var ordinals: [RoadIntervalLibrary.Category: Int] = [:]
        var used: Set<String> = []
        var names: [String] = []
        var sigs: [String] = []
        func make(_ cat: RoadIntervalLibrary.Category, _ phase: TrainingPhase, _ slot: Int, _ ord: Int, _ rec: Bool) -> IntervalSessionComposer.Composed {
            IntervalSessionComposer.compose(.init(
                category: cat, phase: phase, discipline: .roadMarathon,
                experience: experience, weeklyVolumeKm: volumeKm, paceProfile: prof,
                ordinal: ord, slotIndex: slot, isRecoveryWeek: rec,
                isFirstTimer: false, athleteAge: 32))
        }
        for (phase, wip, rec) in layout {
            for slot in 0..<2 {
                let exclude: RoadIntervalLibrary.Category? = slot == 1
                    ? RoadIntervalLibrary.slotCategory(phase: phase, discipline: .roadMarathon, slotIndex: 0, weekInPhase: wip)
                    : nil
                let cat = RoadIntervalLibrary.slotCategory(phase: phase, discipline: .roadMarathon, slotIndex: slot, weekInPhase: wip, exclude: exclude)
                // Mirror the generator's no-repeat guard.
                if rec {
                    let c = make(cat, phase, slot, ordinals[cat] ?? 0, true)
                    names.append(c.workout.name); sigs.append(c.signature)
                    continue
                }
                var ord = ordinals[cat] ?? 0
                var c = make(cat, phase, slot, ord, false)
                var tries = 0
                while used.contains(c.signature) && tries < 4 { ord += 1; c = make(cat, phase, slot, ord, false); tries += 1 }
                used.insert(c.signature)
                ordinals[cat] = ord + 1
                names.append(c.workout.name); sigs.append(c.signature)
            }
        }
        return (names, sigs)
    }

    @Test("Print quality sequences for two athletes")
    func printSequences() {
        let adv = sequence(volumeKm: 79, experience: .advanced, pb: 2100)   // 35:00 10K
        let int = sequence(volumeKm: 50, experience: .intermediate, pb: 2580) // 43:00 10K
        print("=== ADVANCED 79km (Q1/Q2 per week) ===")
        for (i, pair) in stride(from: 0, to: adv.names.count, by: 2).enumerated() {
            print("W\(String(format: "%02d", i + 1)): Q1=\(adv.names[pair])   Q2=\(adv.names[pair + 1])")
        }
        print("=== INTERMEDIATE 50km ===")
        for (i, pair) in stride(from: 0, to: int.names.count, by: 2).enumerated() {
            print("W\(String(format: "%02d", i + 1)): Q1=\(int.names[pair])   Q2=\(int.names[pair + 1])")
        }
        // After the generator's signature guard, non-recovery work parts must
        // be unique by SIGNATURE (the real guarantee).
        func report(_ label: String, _ seq: (names: [String], signatures: [String])) {
            let recIdx = Set(seq.names.indices.filter { seq.names[$0].contains("strides") || seq.names[$0].contains("primer") })
            let sigs = seq.signatures.indices.filter { !recIdx.contains($0) }.map { seq.signatures[$0] }
            let names = seq.names.indices.filter { !recIdx.contains($0) }.map { seq.names[$0] }
            print("\(label): quality=\(sigs.count) uniqueSig=\(Set(sigs).count) uniqueName=\(Set(names).count)")
        }
        report("ADV", adv)
        report("INT", int)
        print("Sequences differ: \(adv.names != int.names)")
        #expect(true)
    }
}
