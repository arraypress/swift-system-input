// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SystemInput",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SystemInput",
            targets: ["SystemInput"]
        ),
    ],
    targets: [
        .target(
            name: "SystemInput",
            dependencies: [],
            path: "Sources/SystemInput"
        ),
        .testTarget(
            name: "SystemInputTests",
            dependencies: ["SystemInput"],
            path: "Tests/SystemInputTests"
        ),
    ]
)
