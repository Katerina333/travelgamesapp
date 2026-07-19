// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "GameEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GameEngine", targets: ["GameEngine"])
    ],
    dependencies: [
        .package(path: "../CoreKit")
    ],
    targets: [
        .target(name: "GameEngine", dependencies: ["CoreKit"]),
        .testTarget(name: "GameEngineTests", dependencies: ["GameEngine"])
    ]
)
