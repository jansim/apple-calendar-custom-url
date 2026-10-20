import Foundation

/// The meeting link the extension offers, as the app stores it. The app writes
/// it and the extension reads it, both through this type, so the keys cannot
/// drift apart.
public struct MeetingSettings: Sendable, Equatable {
    /// The app's bundle identifier, and so its preferences domain. The
    /// extension is sandboxed and reads this domain through a
    /// shared-preference entitlement naming the same identifier.
    public static let domain = "io.github.jansim.CustomCalendarURL"

    public static let defaultTitle = "Personal Room"

    public enum Key {
        public static let title = "roomTitle"
        public static let url = "roomURL"
        public static let details = "roomDetails"
    }

    public var title: String
    public var url: String
    public var details: String

    public init(title: String = MeetingSettings.defaultTitle, url: String = "", details: String = "") {
        self.title = title
        self.url = url
        self.details = details
    }

    public init(defaults: UserDefaults) {
        self.init(
            title: defaults.string(forKey: Key.title) ?? MeetingSettings.defaultTitle,
            url: defaults.string(forKey: Key.url) ?? "",
            details: defaults.string(forKey: Key.details) ?? ""
        )
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(title, forKey: Key.title)
        defaults.set(url, forKey: Key.url)
        defaults.set(details, forKey: Key.details)
    }

    /// What Calendar shows in its video call menu. Never empty, since a
    /// nameless entry there would be unclickable.
    public var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? MeetingSettings.defaultTitle : trimmed
    }

    public var link: URL? { MeetingLink.parse(url) }

    public var trimmedDetails: String? {
        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
