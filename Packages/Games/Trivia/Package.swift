// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Trivia",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Trivia", targets: ["Trivia"])
    ],
    dependencies: [
        .package(path: "../../CoreKit"),
        .package(path: "../../GameEngine"),
        .package(path: "../../ContentKit"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "Trivia", dependencies: ["CoreKit", "GameEngine", "ContentKit", "DesignSystem"]),
        .testTarget(name: "TriviaTests", dependencies: ["Trivia"])
    ]
)
