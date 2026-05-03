// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Clamshell",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Clamshell", targets: ["Clamshell"])
    ],
    targets: [
        .executableTarget(
            name: "Clamshell",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
