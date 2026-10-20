import SwiftUI
import AppKit

@main
enum Main {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--selftest") {
            exit(SelfTest.run())
        }
        CustomCalendarURLApp.main()
    }
}

struct CustomCalendarURLApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        Window("Custom Calendar URL", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}

/// The settings window is the whole app; nothing needs to keep running once
/// it is closed, since Calendar launches the extension on its own.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
