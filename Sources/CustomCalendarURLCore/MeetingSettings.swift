import Foundation

/// One entry in Calendar's video call options.
public struct MeetingRoom: Codable, Sendable, Equatable, Identifiable {
    /// Also the room type identifier Calendar hands back when the entry is
    /// picked, so it stays fixed when the room is renamed or its link changes.
    public var id: String
    public var title: String
    public var url: String
    public var details: String

    public init(id: String = UUID().uuidString, title: String = "", url: String = "", details: String = "") {
        self.id = id
        self.title = title
        self.url = url
        self.details = details
    }

    /// What Calendar shows in its video call menu. Never empty, since a
    /// nameless entry there would be unclickable.
    public var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return link?.host() ?? MeetingRoom.untitled
    }

    public static let untitled = "Untitled Room"

    public var link: URL? { MeetingLink.parse(url) }

    public var trimmedDetails: String? {
        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// The rooms the extension offers, as the app stores them. The app writes
/// them and the extension reads them, both through this type, so the storage
/// format cannot drift apart.
public struct MeetingSettings: Sendable, Equatable {
    /// The app's bundle identifier, and so its preferences domain. The
    /// extension is sandboxed and reads this domain through a
    /// shared-preference entitlement naming the same identifier.
    public static let domain = "io.github.jansim.CustomCalendarURL"

    public static let roomsKey = "rooms"

    /// In the order Calendar lists them.
    public var rooms: [MeetingRoom]

    public init(rooms: [MeetingRoom] = []) {
        self.rooms = rooms
    }

    /// Unreadable data reads as no rooms: the extension then offers nothing
    /// rather than failing every time Calendar asks.
    public init(defaults: UserDefaults) {
        let data = defaults.data(forKey: MeetingSettings.roomsKey)
        self.init(rooms: data.flatMap { try? JSONDecoder().decode([MeetingRoom].self, from: $0) } ?? [])
    }

    public func save(to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(rooms) else { return }
        defaults.set(data, forKey: MeetingSettings.roomsKey)
    }

    public func room(id: String) -> MeetingRoom? {
        rooms.first { $0.id == id }
    }
}

public enum MeetingLink {
    /// The URL a typed or pasted link stands for, or nil if it is not one.
    public static func parse(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else { return nil }

        // Room links are often copied without their scheme ("zoom.us/my/jane").
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              let host = components.host, !host.isEmpty
        else { return nil }

        // A bare word like "zoom" would otherwise pass as https://zoom.
        if scheme == "http" || scheme == "https" {
            guard host.contains(".") || host == "localhost" else { return nil }
        }
        return components.url
    }
}
