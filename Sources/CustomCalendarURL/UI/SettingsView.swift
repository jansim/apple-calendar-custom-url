import SwiftUI
import CustomCalendarURLCore

/// Edits the rooms, one section each, in the order Calendar lists them.
struct SettingsView: View {
    @State private var model = RoomsModel()

    var body: some View {
        Form {
            ForEach($model.rooms) { $room in
                RoomSection(room: $room) { model.remove(id: room.id) }
            }

            Section {
                Button("Add Room", systemImage: "plus") { model.add() }
            } footer: {
                Text("Each link with a valid URL shows up by name in the video call options of an event’s location field in Calendar. If they are missing, open Calendar again, and check that the Custom Calendar URL extension is turned on in System Settings › General › Login Items & Extensions.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .frame(minHeight: 320, idealHeight: 520)
    }
}

private struct RoomSection: View {
    @Binding var room: MeetingRoom
    let onRemove: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            TextField("Link", text: $room.url, prompt: Text("https://example.com/my-room"))
            TextField("Name", text: $room.title, prompt: Text(room.suggestedTitle ?? "Personal Room"))
            TextField("Details", text: $room.details, prompt: Text("Optional, e.g. a passcode"), axis: .vertical)
                .lineLimit(2...4)
        } header: {
            HStack {
                Text(room.displayTitle)
                Spacer()
                Button("Remove", systemImage: "minus.circle", role: .destructive, action: onRemove)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Remove this link")
            }
        } footer: {
            status
        }
    }

    @ViewBuilder private var status: some View {
        if room.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Label("Enter the link to offer in Calendar.", systemImage: "info.circle")
                .foregroundStyle(.secondary)
        } else if let link = room.link {
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
