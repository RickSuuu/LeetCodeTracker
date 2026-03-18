// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LeetCodeTracker",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LeetCodeTracker",
            path: "Sources"
        )
    ]
)
