// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TFYSwiftPanModelKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TFYSwiftPanModelKit",
            targets: ["TFYSwiftPanModelKit"]
        ),
    ],
    targets: [
        .target(
            name: "TFYSwiftPanModelKit",
            path: "TFYSwiftPanModelKit/TFYSwiftPanModel",
            sources: [
                "Tools",
                "popController",
                "popView"
            ]
        ),
    ]
)
