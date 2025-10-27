// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "yclock",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "yclock", targets: ["yclock"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "yClockLib",
            path: "yclock",
            exclude: ["info.plist", "main.swift", "yclock.png", "yclock.icns"],
            sources: ["app-delegate.swift", "clock-view.swift", "theme.swift", "command-line.swift"],
            linkerSettings: [
                .linkedFramework("Cocoa")
            ]
        ),
        .executableTarget(
            name: "yclock",
            dependencies: ["yClockLib"],
            path: "yclock",
            exclude: ["info.plist", "app-delegate.swift", "clock-view.swift", "theme.swift", "command-line.swift", "yclock.png", "yclock.icns"],
            sources: ["main.swift"],
            linkerSettings: [
                .linkedFramework("Cocoa")
            ]
        ),
        .testTarget(
            name: "yClockTests",
            dependencies: [
                "yClockLib",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "tests"
        ),
    ]
)
