// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "ios-app",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "TrustNetCore", targets: ["TrustNetCore"]),
    ],
    targets: [
        .target(name: "TrustNetCore", path: "Sources"),
        .testTarget(
            name: "TrustNetCoreTests",
            dependencies: ["TrustNetCore"],
            path: "Tests"
        ),
    ]
)
