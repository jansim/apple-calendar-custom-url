// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CustomCalendarURL",
    platforms: [.macOS(.v14)],
    targets: [
        // Everything both processes agree on: the settings keys, link parsing,
        // and the descriptors handed to Calendar.
        .target(
            name: "CustomCalendarURLCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // The settings app, and the bundle the extension ships inside.
        .executableTarget(
            name: "CustomCalendarURL",
            dependencies: ["CustomCalendarURLCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // The EKVirtualConferenceProvider. Scripts/build.sh wraps it in an
        // .appex; the system starts it through NSExtensionMain, not `main`.
        .executableTarget(
            name: "CustomCalendarURLExtension",
            dependencies: ["CustomCalendarURLCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .unsafeFlags(["-application-extension"]),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-e", "-Xlinker", "_NSExtensionMain",
                    "-Xlinker", "-application_extension",
                ])
            ]
        ),
    ]
)
