import EventKit
import CustomURLCore

/// The extension's principal class, named in its Info.plist. Calendar asks it
/// for room types when the video call menu opens, and for the conference once
/// one is picked. Settings are read fresh each time, so a link changed in the
/// app applies without restarting anything.
@objc(ConferenceProvider)
final class ConferenceProvider: EKVirtualConferenceProvider {
    private var settings: MeetingSettings {
        MeetingSettings(defaults: UserDefaults(suiteName: MeetingSettings.domain) ?? .standard)
    }

    override func fetchAvailableRoomTypes() async throws -> [EKVirtualConferenceRoomTypeDescriptor] {
        Conference.roomTypes(for: settings)
    }

    override func fetchVirtualConference(
        identifier: EKVirtualConferenceRoomTypeIdentifier
    ) async throws -> EKVirtualConferenceDescriptor {
        try Conference.descriptor(for: identifier, settings: settings)
    }
}
