import Foundation
import EventKit
import CustomCalendarURLCore

/// Headless checks of everything the extension answers Calendar with, plus,
/// when run from the built app, the bundle wiring Calendar relies on to find
/// it. Run with `CustomCalendarURL --selftest`; exits non-zero on any failure.
enum SelfTest {
    @MainActor
    static func run() -> Int32 {
        var failures = 0
        func check(_ ok: Bool, _ label: String) {
            print(ok ? "✓" : "✗", label)
            if !ok { failures += 1 }
        }

        print("Links")
        for (input, expected) in [
            ("https://zoom.us/my/jane", "https://zoom.us/my/jane"),
            ("  https://meet.example.com/abc-defg-hij \n", "https://meet.example.com/abc-defg-hij"),
            ("zoom.us/my/jane", "https://zoom.us/my/jane"),
            ("http://localhost:8080/room", "http://localhost:8080/room"),
            ("zoommtg://zoom.us/join?confno=123", "zoommtg://zoom.us/join?confno=123"),
        ] {
            check(MeetingLink.parse(input)?.absoluteString == expected, "\(input.debugDescription) → \(expected)")
        }
        for input in ["", "   ", "zoom", "https://", "not a link", "https://zoom.us/my jane"] {
            check(MeetingLink.parse(input) == nil, "\(input.debugDescription) is rejected")
        }

        print("\nSettings")
        let jane = MeetingRoom(title: "Jane’s Room", url: "zoom.us/my/jane", details: "Passcode 1234")
        let team = MeetingRoom(title: "Team", url: "https://meet.jit.si/team")
        let draft = MeetingRoom(title: "Draft", url: "zoom")
        let suite = "customcalendarurl-selftest-\(UUID().uuidString)"
        if let defaults = UserDefaults(suiteName: suite) {
            defer { defaults.removePersistentDomain(forName: suite) }
            check(MeetingSettings(defaults: defaults).rooms.isEmpty, "empty defaults read as no rooms")
            let saved = MeetingSettings(rooms: [jane, draft, team])
            saved.save(to: defaults)
            check(MeetingSettings(defaults: defaults) == saved, "rooms round-trip, in order")
            defaults.set(Data("not json".utf8), forKey: MeetingSettings.roomsKey)
            check(MeetingSettings(defaults: defaults).rooms.isEmpty, "unreadable rooms read as none")
        } else {
            check(false, "scratch defaults suite opens")
        }

        let modelSuite = "customcalendarurl-selftest-\(UUID().uuidString)"
        if let defaults = UserDefaults(suiteName: modelSuite) {
            defer { defaults.removePersistentDomain(forName: modelSuite) }
            let model = RoomsModel(defaults: defaults)
            check(model.rooms.count == 1 && model.rooms[0].url.isEmpty, "a first launch opens on one empty room")
            model.rooms[0].url = "zoom.us/my/jane"
            model.add()
            model.rooms[1].url = "meet.jit.si/team"
            check(MeetingSettings(defaults: defaults).rooms.map(\.url) == ["zoom.us/my/jane", "meet.jit.si/team"],
                  "edits and additions are saved as they happen")
            model.remove(id: model.rooms[0].id)
            check(MeetingSettings(defaults: defaults).rooms.map(\.url) == ["meet.jit.si/team"], "removals are saved")
            check(RoomsModel(defaults: defaults).rooms == model.rooms, "a relaunch reads the saved rooms back")
        } else {
            check(false, "scratch defaults suite opens")
        }

        check(MeetingRoom().id != MeetingRoom().id, "new rooms get distinct identifiers")
        check(MeetingRoom(title: "  ", url: "zoom.us/my/jane").displayTitle == "zoom.us",
              "a blank name falls back to the link's host")
        check(MeetingRoom(title: "  ").displayTitle == MeetingRoom.untitled, "and without a link, to a placeholder")
        check(MeetingRoom(details: " \n").trimmedDetails == nil, "blank details are left out")

        print("\nConference")
        check(Conference.roomTypes(for: MeetingSettings()).isEmpty, "no rooms, no room types")

        let settings = MeetingSettings(rooms: [jane, draft, team])
        let types = Conference.roomTypes(for: settings)
        check(types.map(\.title) == ["Jane’s Room", "Team"], "one room type per usable room, in order")
        check(types.map(\.identifier) == [jane.id, team.id], "room types carry the rooms' identifiers")

        check(throwsError(.noLink) { _ = try Conference.descriptor(for: draft.id, settings: settings) },
              "a room without a usable link throws when picked")
        check(throwsError(.unknownRoomType("gone")) { _ = try Conference.descriptor(for: "gone", settings: settings) },
              "a deleted room throws when picked")

        if let conference = try? Conference.descriptor(for: jane.id, settings: settings) {
            check(conference.title == "Jane’s Room", "conference carries the name")
            check(conference.urlDescriptors.map(\.url.absoluteString) == ["https://zoom.us/my/jane"],
                  "conference carries the normalized link")
            check(conference.conferenceDetails == "Passcode 1234", "conference carries the details")
        } else {
            check(false, "conference builds")
        }
        if let conference = try? Conference.descriptor(for: team.id, settings: settings) {
            check(conference.urlDescriptors.map(\.url.absoluteString) == ["https://meet.jit.si/team"],
                  "each room answers with its own link")
            check(conference.conferenceDetails == nil, "and its own details")
        } else {
            check(false, "second conference builds")
        }

        if Bundle.main.bundleURL.pathExtension == "app" {
            print("\nBundle")
            checkBundle(check)
        }

        print(failures == 0 ? "\nAll checks passed." : "\n\(failures) check(s) failed.")
        return failures == 0 ? 0 : 1
    }

    /// Calendar only finds the provider if the appex is embedded, declares the
    /// right extension point and class, and the app's defaults live where the
    /// extension's entitlement says they do.
    private static func checkBundle(_ check: (Bool, String) -> Void) {
        check(Bundle.main.bundleIdentifier == MeetingSettings.domain,
              "app identifier is the domain the extension reads")

        guard let plugins = Bundle.main.builtInPlugInsURL,
              let appex = Bundle(url: plugins.appendingPathComponent("CustomCalendarURLExtension.appex"))
        else {
            check(false, "extension is embedded")
            return
        }
        check(true, "extension is embedded")
        check(appex.bundleIdentifier?.hasPrefix(MeetingSettings.domain + ".") == true,
              "extension identifier is prefixed with the app's")

        let info = appex.infoDictionary?["NSExtension"] as? [String: Any]
        check(info?["NSExtensionPointIdentifier"] as? String == "com.apple.calendar.virtualconference",
              "extension point is com.apple.calendar.virtualconference")
        check(info?["NSExtensionPrincipalClass"] as? String == "ConferenceProvider",
              "principal class is ConferenceProvider")
    }

    private static func throwsError(_ expected: ConferenceError, _ body: () throws -> Void) -> Bool {
        do { try body(); return false } catch { return (error as? ConferenceError) == expected }
    }
}
