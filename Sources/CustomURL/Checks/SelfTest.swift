import Foundation
import EventKit
import CustomURLCore

/// Headless checks of everything the extension answers Calendar with, plus,
/// when run from the built app, the bundle wiring Calendar relies on to find
/// it. Run with `CustomURL --selftest`; exits non-zero on any failure.
enum SelfTest {
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
        let suite = "customurl-selftest-\(UUID().uuidString)"
        if let defaults = UserDefaults(suiteName: suite) {
            defer { defaults.removePersistentDomain(forName: suite) }
            check(MeetingSettings(defaults: defaults) == MeetingSettings(), "empty defaults read as the defaults")
            let saved = MeetingSettings(title: "Jane’s Room", url: "zoom.us/my/jane", details: "Passcode 1234")
            saved.save(to: defaults)
            check(MeetingSettings(defaults: defaults) == saved, "settings round-trip")
        } else {
            check(false, "scratch defaults suite opens")
        }
        check(MeetingSettings(title: "  ").displayTitle == MeetingSettings.defaultTitle, "a blank name falls back")
        check(MeetingSettings(details: " \n").trimmedDetails == nil, "blank details are left out")

        print("\nConference")
        let unset = MeetingSettings()
        check(Conference.roomTypes(for: unset).isEmpty, "no link, no room type")
        check(Conference.roomTypes(for: MeetingSettings(url: "zoom")).isEmpty, "an invalid link, no room type")
        check(throwsError(.noLink) { try Conference.descriptor(for: Conference.roomTypeIdentifier, settings: unset) },
              "no link throws when picked")

        let set = MeetingSettings(title: "Jane’s Room", url: "zoom.us/my/jane", details: "Passcode 1234")
        let types = Conference.roomTypes(for: set)
        check(types.count == 1, "one room type")
        check(types.first?.title == "Jane’s Room", "room type carries the name")
        check(types.first?.identifier == Conference.roomTypeIdentifier, "room type carries the identifier")
        check(throwsError(.unknownRoomType("other")) { try Conference.descriptor(for: "other", settings: set) },
              "an unknown room type throws")

        if let conference = try? Conference.descriptor(for: Conference.roomTypeIdentifier, settings: set) {
            check(conference.title == "Jane’s Room", "conference carries the name")
            check(conference.urlDescriptors.map(\.url.absoluteString) == ["https://zoom.us/my/jane"],
                  "conference carries the normalized link")
            check(conference.conferenceDetails == "Passcode 1234", "conference carries the details")
        } else {
            check(false, "conference builds")
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
              let appex = Bundle(url: plugins.appendingPathComponent("CustomURLExtension.appex"))
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
