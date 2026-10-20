import EventKit
import CustomCalendarURLCore

/// The extension's principal class, named in its Info.plist. Calendar asks it
/// for room types when the video call menu opens, and for the conference once
/// one is picked. Settings are read fresh each time, so a link changed in the
/// app applies without restarting anything.
@objc(ConferenceProvider)
final class ConferenceProvider: EKVirtualConferenceProvider {
    private var settings: MeetingSettings {
        MeetingSettings(defaults: UserDefaults(suiteName: MeetingSettings.domain) ?? .standard)
    }

    // The completion-handler forms rather than the async ones: EventKit's
    // descriptors are not Sendable, so Swift 6 will not let an async override
    // return them, and nothing here needs to suspend anyway.
    override func fetchAvailableRoomTypes(
        completionHandler: @escaping ([EKVirtualConferenceRoomTypeDescriptor]?, (any Error)?) -> Void
    ) {
        completionHandler(Conference.roomTypes(for: settings), nil)
    }

    override func fetchVirtualConference(
        identifier: EKVirtualConferenceRoomTypeIdentifier,
        completionHandler: @escaping (EKVirtualConferenceDescriptor?, (any Error)?) -> Void
    ) {
        do {
            completionHandler(try Conference.descriptor(for: identifier, settings: settings), nil)
        } catch {
            completionHandler(nil, error)
        }
    }
}
