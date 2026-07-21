// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Charades",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Charades", targets: ["Charades"])
    ],
    dependencies: [
        .package(path: "../../CoreKit"),
        .package(path: "../../GameEngine"),
        .package(path: "../../ContentKit"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(name: "Charades", dependencies: ["CoreKit", "GameEngine", "ContentKit", "DesignSystem"]),
        .testTarget(name: "CharadesTests", dependencies: ["Charades"])
    ]
)
