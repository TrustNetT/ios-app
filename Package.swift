// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ios-app",
    products: [
        .library(name: "TrustNetCore", targets: ["TrustNetCore"]),
    ],
    targets: [
        .target(name: "TrustNetCore", path: "Sources"),
        .testTarget(name: "TrustNetCoreTests", dependencies: ["TrustNetCore"], path: "Tests"),
    ]
)
