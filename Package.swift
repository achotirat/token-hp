// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TokenCat",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TokenCatCore", targets: ["TokenCatCore"]),
        .executable(name: "TokenCatApp", targets: ["TokenCatApp"]),
        .executable(name: "TokenCatCoreTests", targets: ["TokenCatCoreTests"])
    ],
    targets: [
        .target(name: "TokenCatCore"),
        .executableTarget(
            name: "TokenCatApp",
            dependencies: ["TokenCatCore"]
        ),
        .executableTarget(
            name: "TokenCatCoreTests",
            dependencies: ["TokenCatCore"],
            path: "Tests/TokenCatCoreTests"
        )
    ]
)
