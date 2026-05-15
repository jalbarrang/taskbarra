// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Taskbarra",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Taskbarra", targets: ["Taskbarra"]),
        .library(name: "TaskbarraCore", targets: ["TaskbarraCore"])
    ],
    targets: [
        .target(
            name: "TaskbarraCore",
            path: "Sources/TaskbarraCore"
        ),
        .executableTarget(
            name: "Taskbarra",
            dependencies: ["TaskbarraCore"],
            path: "Sources/Taskbarra"
        ),
        .executableTarget(
            name: "TaskbarraCoreTests",
            dependencies: ["TaskbarraCore"],
            path: "Tests/TaskbarraCoreTests"
        )
    ]
)
