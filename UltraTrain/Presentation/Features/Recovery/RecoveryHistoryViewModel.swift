import Foundation
import os

@Observable
@MainActor
final class RecoveryHistoryViewModel {

    private let recoveryRepository: any RecoveryRepository
    private let morningCheckInRepository: any MorningCheckInRepository

    var entries: [RecoveryHistoryEntry] = []
    var isLoading = false
    var error: String?

    init(
        recoveryRepository: any RecoveryRepository,
        morningCheckInRepository: any MorningCheckInRepository
    ) {
        self.recoveryRepository = recoveryRepository
        self.morningCheckInRepository = morningCheckInRepository
    }

    func load() async {
        isLoading = true
        do {
            let now = Date.now
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!

            let snapshots = try await recoveryRepository.getSnapshots(from: thirtyDaysAgo, to: now)
            let checkIns = try await morningCheckInRepository.getCheckIns(from: thirtyDaysAgo, to: now)

            let calendar = Calendar.current
            var checkInsByDay: [DateComponents: MorningCheckIn] = [:]
            for checkIn in checkIns {
                let comps = calendar.dateComponents([.year, .month, .day], from: checkIn.date)
                checkInsByDay[comps] = checkIn
            }

            var merged: [RecoveryHistoryEntry] = []
            for snapshot in snapshots {
                let comps = calendar.dateComponents([.year, .month, .day], from: snapshot.date)
                let checkIn = checkInsByDay[comps]
                merged.append(RecoveryHistoryEntry(
                    id: snapshot.id,
                    date: snapshot.date,
                    recoveryScore: snapshot.recoveryScore.overallScore,
                    readinessScore: snapshot.readinessScore?.overallScore,
                    checkIn: checkIn
                ))
            }

            entries = merged.sorted { $0.date > $1.date }
        } catch {
            self.error = error.localizedDescription
            Logger.recovery.error("Failed to load recovery history: \(error)")
        }
        isLoading = false
    }
}

struct RecoveryHistoryEntry: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let recoveryScore: Int?
    let readinessScore: Int?
    let checkIn: MorningCheckIn?
}
