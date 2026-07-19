// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ContentKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ContentKit", targets: ["ContentKit"])
    ],
    dependencies: [
        .package(path: "../CoreKit")
    ],
    targets: [
        .target(name: "ContentKit", dependencies: ["CoreKit"], resources: [.process("Packs")]),
        .testTarget(name: "ContentKitTests", dependencies: ["ContentKit"])
    ]
)
