import Vapor

struct ShareRunRequest: Content, Validatable {
    let id: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let duration: Double
    let averagePace: Double
    let gpsTrack: [TrackPointServerDTO]
    let splits: [SplitServerDTO]
    let notes: String?
    let recipientProfileIds: [String]
    let idempotencyKey: String

    static func validations(_ validations: inout Validations) {
        validations.add("distanceKm", as: Double.self, is: .range(0...2000))
        validations.add("elevationGainM", as: Double.self, is: .range(0...30000))
        validations.add("duration", as: Double.self, is: .range(0...604800))
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct SharedRunResponse: Content {
    let id: String
    let sharedByProfileId: String
    let sharedByDisplayName: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let duration: Double
    let averagePace: Double
    let gpsTrack: [TrackPointServerDTO]?
    let splits: [SplitServerDTO]?
    let notes: String?
    let sharedAt: String
    let likeCount: Int
    let commentCount: Int

    init(from model: SharedRunModel, displayName: String) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.sharedByProfileId = model.$user.id.uuidString
        self.sharedByDisplayName = displayName
        self.date = formatter.string(from: model.date)
        self.distanceKm = model.distanceKm
        self.elevationGainM = model.elevationGainM
        self.elevationLossM = model.elevationLossM
        self.duration = model.duration
        self.averagePace = model.averagePace
        self.notes = model.notes
        self.sharedAt = formatter.string(from: model.sharedAt)
        self.likeCount = 0
        self.commentCount = 0

        // Decode GPS track
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let data = model.gpsTrackJSON.data(using: .utf8) {
            self.gpsTrack = try? decoder.decode([TrackPointServerDTO].self, from: data)
        } else {
            self.gpsTrack = nil
        }

        // Decode splits
        if let data = model.splitsJSON.data(using: .utf8) {
            self.splits = try? decoder.decode([SplitServerDTO].self, from: data)
        } else {
            self.splits = nil
        }
    }
}
