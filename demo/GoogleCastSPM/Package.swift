// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoogleCastSPM",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "GoogleCastSPM", targets: ["GoogleCast"]),
    ],
    targets: [
        .binaryTarget(
            name: "GoogleCast",
            url: "https://dl.google.com/dl/chromecast/sdk/ios/GoogleCastSDK-ios-no-bluetooth-4.8.0_dynamic_xcframework.zip",
            checksum: "ae6db94f6fff7720bc28faac2f5dbd0b9c5af0215a1819c4682f7060f21eb1bb"
        ),
    ]
)
