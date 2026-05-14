// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Taskbarra",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Taskbarra", targets: ["Taskbarra"])
    ],
    targets: [
        .executableTarget(
            name: "Taskbarra",
            path: "Sources/Taskbarra"
        )
    ]
)
