// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OmniAct",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OmniAct", targets: ["OmniAct"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "OmniAct",
            dependencies: [],
            path: "Sources/OmniAct"
        ),
        .testTarget(
            name: "OmniActTests",
            dependencies: ["OmniAct"],
            path: "Tests/OmniActTests"
        )
    ]
)
