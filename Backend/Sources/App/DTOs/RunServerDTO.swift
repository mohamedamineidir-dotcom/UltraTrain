import Vapor

struct RunUploadRequest: Content, Validatable {
    let id: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let duration: Double
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averagePaceSecondsPerKm: Double
    let gpsTrack: [TrackPointServerDTO]
    let splits: [SplitServerDTO]
    let notes: String?
    let idempotencyKey: String

    static func validations(_ validations: inout Validations) {
        validations.add("distanceKm", as: Double.self, is: .range(0...1000))
        validations.add("elevationGainM", as: Double.self, is: .range(0...30000))
        validations.add("elevationLossM", as: Double.self, is: .range(0...30000))
        validations.add("duration", as: Double.self, is: .range(1...604800))
        validations.add("idempotencyKey", as: String.self, is: !.empty)
        validations.add("id", as: String.self, is: !.empty)
    }
}

struct TrackPointServerDTO: Content {
    let latitude: Double
    let longitude: Double
    let altitudeM: Double
    let timestamp: String
    let heartRate: Int?
}

struct SplitServerDTO: Content {
    let id: String
    let kilometerNumber: Int
    let duration: Double
    let elevationChangeM: Double
    let averageHeartRate: Int?
}

struct RunResponse: Content {
    let id: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let duration: Double
    let averagePaceSecondsPerKm: Double
    let notes: String?
    let createdAt: String?

    init(from model: RunModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.date = formatter.string(from: model.date)
        self.distanceKm = model.distanceKm
        self.elevationGainM = model.elevationGainM
        self.elevationLossM = model.elevationLossM
        self.duration = model.duration
        self.averagePaceSecondsPerKm = model.averagePaceSecondsPerKm
        self.notes = model.notes
        self.createdAt = model.createdAt.map { formatter.string(from: $0) }
    }
}
