// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TokenCat",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TokenCatCore", targets: ["TokenCatCore"]),
        .executable(name: "TokenCatApp", targets: ["TokenCatApp"])
    ],
    targets: [
        .target(name: "TokenCatCore"),
        .executableTarget(
            name: "TokenCatApp",
            dependencies: ["TokenCatCore"]
        ),
        .testTarget(
            name: "TokenCatCoreTests",
            dependencies: ["TokenCatCore"]
        )
    ]
)
