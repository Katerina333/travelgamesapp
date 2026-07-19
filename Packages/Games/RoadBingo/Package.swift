// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RoadBingo",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RoadBingo", targets: ["RoadBingo"])
    ],
    dependencies: [
        .package(path: "../../CoreKit"),
        .package(path: "../../GameEngine"),
        .package(path: "../../ContentKit"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "RoadBingo", dependencies: ["CoreKit", "GameEngine", "ContentKit", "DesignSystem"]),
        .testTarget(name: "RoadBingoTests", dependencies: ["RoadBingo"])
    ]
)
