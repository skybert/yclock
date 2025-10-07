// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "yclock",
    platforms: [
        .macOS(.v11)
    ],
    targets: [
        .executableTarget(
            name: "yclock",
            path: "yclock",
            exclude: ["info.plist"],
            linkerSettings: [
                .linkedFramework("Cocoa")
            ]
        ),
    ]
)
