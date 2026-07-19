// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PaywallKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PaywallKit", targets: ["PaywallKit"])
    ],
    dependencies: [
        .package(path: "../CoreKit")
    ],
    targets: [
        .target(name: "PaywallKit", dependencies: ["CoreKit"]),
        .testTarget(name: "PaywallKitTests", dependencies: ["PaywallKit"])
    ]
)
