// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "promptly-ios",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "promptly-ios",
            targets: ["promptly-ios"]),
    ],
    dependencies: [
        // No external dependencies - keeping it lightweight!
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "promptly-ios",
            dependencies: [],
            resources: [
                // Include any resources if needed
            ]),
        .testTarget(
            name: "promptly-iosTests",
            dependencies: ["promptly-ios"]),
    ]
)
