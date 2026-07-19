// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TripKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TripKit", targets: ["TripKit"])
    ],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../GameEngine")
    ],
    targets: [
        .target(name: "TripKit", dependencies: ["CoreKit", "GameEngine"]),
        .testTarget(name: "TripKitTests", dependencies: ["TripKit"])
    ]
)
