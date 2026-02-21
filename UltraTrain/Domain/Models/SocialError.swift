import Foundation

enum SocialError: Error, Equatable, Sendable {
    case notAuthenticated
    case profileNotFound
    case friendRequestAlreadySent
    case friendRequestNotFound
    case alreadyFriends
    case shareCreationFailed(reason: String)
    case shareAcceptFailed(reason: String)
    case cloudKitPermissionDenied
    case cloudKitUnavailable
    case recordNotFound
    case zoneFetchFailed(reason: String)
    case quotaExceeded
    case networkError(reason: String)
}

extension SocialError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You need to be signed into iCloud to use social features."
        case .profileNotFound:
            return "Social profile not found."
        case .friendRequestAlreadySent:
            return "A friend request has already been sent to this person."
        case .friendRequestNotFound:
            return "Friend request not found."
        case .alreadyFriends:
            return "You are already friends with this person."
        case .shareCreationFailed(let reason):
            return "Failed to share: \(reason)"
        case .shareAcceptFailed(let reason):
            return "Failed to accept share: \(reason)"
        case .cloudKitPermissionDenied:
            return "CloudKit permission denied. Please allow access in Settings."
        case .cloudKitUnavailable:
            return "iCloud is not available. Sign in to iCloud in iOS Settings."
        case .recordNotFound:
            return "Record not found in CloudKit."
        case .zoneFetchFailed(let reason):
            return "Failed to fetch data: \(reason)"
        case .quotaExceeded:
            return "iCloud storage quota exceeded."
        case .networkError(let reason):
            return "Network error: \(reason)"
        }
    }
}
