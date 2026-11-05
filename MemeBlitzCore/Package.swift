// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MemeBlitzCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MemeBlitzCore", targets: ["MemeBlitzCore"]),
    ],
    targets: [
        .target(name: "MemeBlitzCore"),
        .testTarget(name: "MemeBlitzCoreTests", dependencies: ["MemeBlitzCore"]),
    ]
)
