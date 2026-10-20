import SwiftUI
import CustomCalendarURLCore

/// Edits the link in the app's own defaults, which the extension reads.
struct SettingsView: View {
    @AppStorage(MeetingSettings.Key.title) private var title = MeetingSettings.defaultTitle
    @AppStorage(MeetingSettings.Key.url) private var url = ""
    @AppStorage(MeetingSettings.Key.details) private var details = ""

    @Environment(\.openURL) private var openURL

    private var settings: MeetingSettings {
        MeetingSettings(title: title, url: url, details: details)
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $title, prompt: Text(MeetingSettings.defaultTitle))
                TextField("Link", text: $url, prompt: Text("https://example.com/my-room"))
                TextField("Details", text: $details, prompt: Text("Optional, e.g. a passcode"), axis: .vertical)
                    .lineLimit(2...4)
            } footer: {
                status
            }

            Section("In Calendar") {
                Text("Click an event’s location field and pick “\(settings.displayTitle)” from the video call options. If it is missing, open Calendar again, and check that the Custom Calendar URL extension is turned on in System Settings › General › Login Items & Extensions.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
    }

    @ViewBuilder private var status: some View {
        if url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Label("Enter the link to offer in Calendar.", systemImage: "info.circle")
                .foregroundStyle(.secondary)
        } else if let link = settings.link {
            HStack {
                Label(link.absoluteString, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Open") { openURL(link) }
            }
        } else {
            Label("This is not a link Calendar can open.", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }
}
