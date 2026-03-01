import Foundation
import Testing
@testable import UltraTrain

@Suite("PersonalBest Tests")
struct PersonalBestTests {

    // MARK: - Distance

    @Test("5K distance is 5.0 km")
    func fiveKDistance() {
        #expect(PersonalBestDistance.fiveK.distanceKm == 5.0)
    }

    @Test("10K distance is 10.0 km")
    func tenKDistance() {
        #expect(PersonalBestDistance.tenK.distanceKm == 10.0)
    }

    @Test("half marathon distance is 21.0975 km")
    func halfMarathonDistance() {
        #expect(PersonalBestDistance.halfMarathon.distanceKm == 21.0975)
    }

    @Test("marathon distance is 42.195 km")
    func marathonDistance() {
        #expect(PersonalBestDistance.marathon.distanceKm == 42.195)
    }

    // MARK: - Pace

    @Test("pace per km is calculated correctly")
    func pacePerKm() {
        let pb = PersonalBest(
            id: UUID(),
            distance: .fiveK,
            timeSeconds: 1200, // 20 minutes
            date: .now
        )
        #expect(pb.pacePerKm == 240.0) // 4 min/km = 240 seconds/km
    }

    // MARK: - Recency Weight

    @Test("recent performance has weight close to 1.0")
    func recentWeight() {
        let pb = PersonalBest(
            id: UUID(),
            distance: .tenK,
            timeSeconds: 2400,
            date: .now
        )
        let weight = pb.recencyWeight()
        #expect(weight > 0.95)
    }

    @Test("performance from 180 days ago has weight close to 0.5")
    func halfLifeWeight() {
        let halfLifeAgo = Calendar.current.date(byAdding: .day, value: -180, to: .now)!
        let pb = PersonalBest(
            id: UUID(),
            distance: .tenK,
            timeSeconds: 2400,
            date: halfLifeAgo
        )
        let weight = pb.recencyWeight()
        #expect(abs(weight - 0.5) < 0.05)
    }

    @Test("performance from 360 days ago has weight close to 0.25")
    func doubleHalfLifeWeight() {
        let twoHalfLivesAgo = Calendar.current.date(byAdding: .day, value: -360, to: .now)!
        let pb = PersonalBest(
            id: UUID(),
            distance: .halfMarathon,
            timeSeconds: 5400,
            date: twoHalfLivesAgo
        )
        let weight = pb.recencyWeight()
        #expect(abs(weight - 0.25) < 0.05)
    }

    @Test("future date returns weight of 1.0")
    func futureDate() {
        let future = Calendar.current.date(byAdding: .day, value: 30, to: .now)!
        let pb = PersonalBest(
            id: UUID(),
            distance: .fiveK,
            timeSeconds: 1200,
            date: future
        )
        let weight = pb.recencyWeight()
        #expect(weight == 1.0)
    }

    // MARK: - Codable

    @Test("PersonalBest encodes and decodes correctly")
    func codable() throws {
        let original = PersonalBest(
            id: UUID(),
            distance: .marathon,
            timeSeconds: 12600,
            date: Date(timeIntervalSince1970: 1700000000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PersonalBest.self, from: data)
        #expect(decoded == original)
    }

    @Test("all distances have short labels")
    func shortLabels() {
        for distance in PersonalBestDistance.allCases {
            #expect(!distance.shortLabel.isEmpty)
        }
    }
}
