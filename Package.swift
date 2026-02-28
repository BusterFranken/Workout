// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WorkoutTracker",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WorkoutTrackerApp", targets: ["WorkoutTrackerApp"])
    ],
    targets: [
        .executableTarget(
            name: "WorkoutTrackerApp",
            path: "Sources/WorkoutTrackerApp"
        )
    ]
)
