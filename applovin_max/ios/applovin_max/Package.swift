// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "applovin_max",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "applovin-max", targets: ["applovin_max"])
    ],
    dependencies: [
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package", from: "13.6.1")
    ],
    targets: [
        .target(
            name: "applovin_max",
            dependencies: [
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package")
            ],
            path: "Sources/applovin_max",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .define("DEFINES_MODULE")
            ]
        )
    ]
)
