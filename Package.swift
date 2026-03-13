// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "shot-cli",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "shot-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/shot-cli"
        ),
        .testTarget(
            name: "ShotTests",
            dependencies: ["shot-cli"],
            path: "Tests/ShotTests"
        ),
    ]
)
