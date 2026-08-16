// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KantanZip",
    defaultLocalization: "ja",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "KantanZipCore"),
        .executableTarget(name: "KantanZipApp", dependencies: ["KantanZipCore"]),
        .testTarget(name: "KantanZipCoreTests", dependencies: ["KantanZipCore"]),
    ]
)
