// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "applovin_max",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "applovin-max", targets: ["applovin_max"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // AppLovinSDK is published as a Swift package only. Keep the requirement on one line: the release script
        // reads and bumps the version on it.
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", exact: "13.6.3")
    ],
    targets: [
        .target(
            name: "applovin_max",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package")
            ],
            cSettings: [
                .headerSearchPath("include/applovin_max")
            ]
        )
    ]
)
