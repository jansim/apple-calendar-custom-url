import EventKit

/// Builds what the extension answers Calendar with, so the answers can be
/// checked without Calendar in the loop.
public enum Conference {
    /// One room type per room with a usable link. A room still being filled
    /// in is left out, rather than offered and failing once picked.
    public static func roomTypes(for settings: MeetingSettings) -> [EKVirtualConferenceRoomTypeDescriptor] {
        settings.rooms.filter { $0.link != nil }.map {
            EKVirtualConferenceRoomTypeDescriptor(title: $0.displayTitle, identifier: $0.id)
        }
    }

    public static func descriptor(for identifier: EKVirtualConferenceRoomTypeIdentifier,
                                  settings: MeetingSettings) throws -> EKVirtualConferenceDescriptor {
        // The menu can go stale while open: the room may have been deleted or
        // its link cleared in the app since Calendar asked for room types.
        guard let room = settings.room(id: identifier) else { throw ConferenceError.unknownRoomType(identifier) }
        guard let url = room.link else { throw ConferenceError.noLink }
        return EKVirtualConferenceDescriptor(
            title: room.displayTitle,
            urlDescriptors: [EKVirtualConferenceURLDescriptor(title: nil, url: url)],
            conferenceDetails: room.trimmedDetails
        )
    }
}

public enum ConferenceError: LocalizedError, Equatable {
    case noLink
    case unknownRoomType(String)

    public var errorDescription: String? {
        switch self {
        case .noLink: "This room has no link. Open Custom Calendar URL to set one."
        case .unknownRoomType: "This room no longer exists. Open Custom Calendar URL to check your rooms."
        }
    }
}
