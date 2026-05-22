// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TrainingKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .watchOS(.v8)],
    products: [
        .library(
            name: "TrainingKit",
            targets: ["TrainingKit"]
        ),
    ],

    targets: [
        .binaryTarget(
            name: "TrainingKit",
            path: "TrainingKit.xcframework"
        ),
    ]
)
