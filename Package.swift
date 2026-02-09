// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "ios-app",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "TrustNetCore", targets: ["TrustNetCore"]),
        .executable(name: "test-validator", targets: ["ValidatorTests"]),
    ],
    targets: [
        .target(name: "TrustNetCore", path: "Sources"),
        .executableTarget(
            name: "ValidatorTests",
            dependencies: ["TrustNetCore"],
            path: "Tests"
        ),
    ]
)
