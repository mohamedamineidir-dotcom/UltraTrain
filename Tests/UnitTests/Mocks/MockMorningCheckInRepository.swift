import Foundation
@testable import UltraTrain

final class MockMorningCheckInRepository: MorningCheckInRepository, @unchecked Sendable {
    var checkIns: [MorningCheckIn] = []
    var saveCalledWith: [MorningCheckIn] = []

    func getCheckIn(for date: Date) async throws -> MorningCheckIn? {
        let calendar = Calendar.current
        return checkIns.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func saveCheckIn(_ checkIn: MorningCheckIn) async throws {
        saveCalledWith.append(checkIn)
        if let index = checkIns.firstIndex(where: { $0.id == checkIn.id }) {
            checkIns[index] = checkIn
        } else {
            checkIns.append(checkIn)
        }
    }

    func getCheckIns(from startDate: Date, to endDate: Date) async throws -> [MorningCheckIn] {
        checkIns.filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date < $1.date }
    }
}
