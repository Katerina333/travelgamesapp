// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WouldYouRather",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WouldYouRather", targets: ["WouldYouRather"])
    ],
    dependencies: [
        .package(path: "../../CoreKit"),
        .package(path: "../../GameEngine"),
        .package(path: "../../ContentKit"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "WouldYouRather", dependencies: ["CoreKit", "GameEngine", "ContentKit", "DesignSystem"]),
        .testTarget(name: "WouldYouRatherTests", dependencies: ["WouldYouRather"])
    ]
)
