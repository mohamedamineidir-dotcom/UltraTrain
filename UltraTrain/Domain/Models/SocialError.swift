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
            return String(localized: "serr.notAuth", defaultValue: "You need to be signed into iCloud to use social features.")
        case .profileNotFound:
            return String(localized: "serr.profileNotFound", defaultValue: "Social profile not found.")
        case .friendRequestAlreadySent:
            return String(localized: "serr.friendAlreadySent", defaultValue: "A friend request has already been sent to this person.")
        case .friendRequestNotFound:
            return String(localized: "serr.friendNotFound", defaultValue: "Friend request not found.")
        case .alreadyFriends:
            return String(localized: "serr.alreadyFriends", defaultValue: "You are already friends with this person.")
        case .shareCreationFailed(let reason):
            return String(localized: "serr.shareCreateFailed", defaultValue: "Failed to share: \(reason)")
        case .shareAcceptFailed(let reason):
            return String(localized: "serr.shareAcceptFailed", defaultValue: "Failed to accept share: \(reason)")
        case .cloudKitPermissionDenied:
            return String(localized: "serr.ckPermission", defaultValue: "CloudKit permission denied. Please allow access in Settings.")
        case .cloudKitUnavailable:
            return String(localized: "serr.ckUnavailable", defaultValue: "iCloud is not available. Sign in to iCloud in iOS Settings.")
        case .recordNotFound:
            return String(localized: "serr.recordNotFound", defaultValue: "Record not found in CloudKit.")
        case .zoneFetchFailed(let reason):
            return String(localized: "serr.zoneFetchFailed", defaultValue: "Failed to fetch data: \(reason)")
        case .quotaExceeded:
            return String(localized: "serr.quota", defaultValue: "iCloud storage quota exceeded.")
        case .networkError(let reason):
            return String(localized: "serr.network", defaultValue: "Network error: \(reason)")
        }
    }
}
