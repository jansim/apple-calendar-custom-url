import EventKit

/// Builds what the extension answers Calendar with, so the answers can be
/// checked without Calendar in the loop.
public enum Conference {
    /// The single room type offered. Calendar hands it back when the user
    /// picks the entry, so it only has to be stable.
    public static let roomTypeIdentifier = "custom-url"

    /// No link configured means no entry at all, rather than one that fails
    /// once picked.
    public static func roomTypes(for settings: MeetingSettings) -> [EKVirtualConferenceRoomTypeDescriptor] {
        guard settings.link != nil else { return [] }
        return [EKVirtualConferenceRoomTypeDescriptor(title: settings.displayTitle,
                                                      identifier: roomTypeIdentifier)]
    }

    public static func descriptor(for identifier: EKVirtualConferenceRoomTypeIdentifier,
                                  settings: MeetingSettings) throws -> EKVirtualConferenceDescriptor {
        guard identifier == roomTypeIdentifier else { throw ConferenceError.unknownRoomType(identifier) }
        guard let url = settings.link else { throw ConferenceError.noLink }
        return EKVirtualConferenceDescriptor(
            title: settings.displayTitle,
            urlDescriptors: [EKVirtualConferenceURLDescriptor(title: nil, url: url)],
            conferenceDetails: settings.trimmedDetails
        )
    }
}

public enum ConferenceError: LocalizedError, Equatable {
    case noLink
    case unknownRoomType(String)

    public var errorDescription: String? {
        switch self {
        case .noLink: "No meeting link is set. Open Custom URL to set one."
        case .unknownRoomType(let id): "Unknown room type “\(id)”."
        }
    }
}
