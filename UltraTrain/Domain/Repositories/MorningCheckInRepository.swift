import Foundation

protocol MorningCheckInRepository: Sendable {
    func getCheckIn(for date: Date) async throws -> MorningCheckIn?
    func saveCheckIn(_ checkIn: MorningCheckIn) async throws
    func getCheckIns(from startDate: Date, to endDate: Date) async throws -> [MorningCheckIn]
}
