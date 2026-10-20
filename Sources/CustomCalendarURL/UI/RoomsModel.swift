import Foundation
import Observation
import CustomCalendarURLCore

/// The rooms being edited. Every change is written straight to the app's
/// defaults, which is where the extension reads them.
@Observable @MainActor
final class RoomsModel {
    var rooms: [MeetingRoom] {
        didSet { MeetingSettings(rooms: rooms).save(to: defaults) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = MeetingSettings(defaults: defaults).rooms
        // A first launch opens on an empty room to fill in, not a blank window.
        rooms = saved.isEmpty ? [MeetingRoom()] : saved
    }

    func add() {
        rooms.append(MeetingRoom())
    }

    func remove(id: MeetingRoom.ID) {
        rooms.removeAll { $0.id == id }
    }
}
