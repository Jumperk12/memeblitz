// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MemePuzzleCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MemePuzzleCore", targets: ["MemePuzzleCore"]),
    ],
    targets: [
        .target(name: "MemePuzzleCore"),
        .testTarget(name: "MemePuzzleCoreTests", dependencies: ["MemePuzzleCore"]),
    ]
)
