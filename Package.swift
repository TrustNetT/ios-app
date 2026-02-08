// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TrustNetApp",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "TrustNetCore", targets: ["TrustNetCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TrustNetCore",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "TrustNetCoreTests",
            dependencies: ["TrustNetCore"],
            path: "Tests"
        ),
    ]
)
