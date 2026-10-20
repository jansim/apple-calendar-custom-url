<p align="center">
  <img src="Resources/CalendarCustomURL-iOS-Default-1024x1024@1x.png" width="257" alt="Custom Calendar URL icon">
</p>

# apple-calendar-custom-url

A minimal macOS app that adds your own meeting links — a personal Zoom room, a
standing Meet or Jitsi link, anything with a URL — to Apple Calendar's video
call options, next to FaceTime.

It does this with an
[`EKVirtualConferenceProvider`](https://developer.apple.com/documentation/eventkit/ekvirtualconferenceprovider)
extension. The app itself is a single settings window listing your links,
each with a name, the URL, and optional details such as a passcode.

No third-party dependencies.

## Building

Requires Xcode 26, for the macOS 26 SDK; CI builds on macOS 26 too. Runs on
macOS 14 or later.

```bash
Scripts/build.sh && open build/CustomCalendarURL.app
```

The script compiles the SwiftPM targets, assembles `build/CustomCalendarURL.app` with
the extension embedded at `Contents/PlugIns/CustomCalendarURLExtension.appex`, and
ad-hoc signs both. The app icon is compiled with `actool` from
`Resources/CalendarCustomURL.icon`, an Icon Composer file.

## Using it

1. Move `CustomCalendarURL.app` to `/Applications` and open it once, so the system
   registers the extension.
2. Enter a link, and optionally a name for it. Until you type one, the link
   goes by a short name read off its URL — `https://zoom.us/my/jane` shows as
   "Zoom: my/jane". Add Link adds another; each one becomes its own entry in
   Calendar, in the order listed.
3. In Calendar, click an event's location field and pick a name from the
   video call options. Calendar fills in that link.

Links without a valid URL are left out of Calendar. If an entry does not show up, quit and reopen Calendar, and check that the
extension is turned on in System Settings › General › Login Items &
Extensions. `pluginkit -m -p com.apple.calendar.virtualconference` lists what
the system has registered.

## How it fits together

| | |
| --- | --- |
| `Sources/CustomCalendarURLCore` | The settings keys, link parsing, and the descriptors handed to Calendar — shared by both targets |
| `Sources/CustomCalendarURL` | The settings app, and the `--selftest` suite |
| `Sources/CustomCalendarURLExtension` | The `EKVirtualConferenceProvider` subclass |
| `Resources/` | Both `Info.plist`s, the extension's entitlements, and the app icon |

The app writes the links, as JSON, to its own defaults. Each link has a
fixed identifier, which is what Calendar hands back when it is picked, so
renaming a link or changing its URL keeps it the same entry. Extensions must be
sandboxed, so the extension reads them through a read-only shared-preference
entitlement naming the app's bundle identifier; an App Group would do the
same but needs a signing team. Settings are read on every request, so a
change applies straight away. Events already created keep the link they were
given, whatever happens to it in the app later.

## Testing

There is no XCTest bundle; the checks are built into the app binary, like in
[doctopus](https://github.com/jansim/doctopus).

```bash
Scripts/build.sh
build/CustomCalendarURL.app/Contents/MacOS/CustomCalendarURL --selftest
```

`--selftest` checks link parsing, saving and reading the links, and everything the
extension answers Calendar with, and — run from the built app — that the
extension is embedded with the right extension point, class and identifiers.
CI additionally verifies the signatures and entitlements, and that `pluginkit`
accepts the extension.
