// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "shot",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "shot",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/shot"
        ),
        .testTarget(
            name: "ShotTests",
            dependencies: ["shot"],
            path: "Tests/ShotTests"
        ),
    ]
)
