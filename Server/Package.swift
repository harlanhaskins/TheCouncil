// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EunuchCouncil",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "EunuchCouncilServer", targets: ["EunuchCouncilServer"]),
        .library(name: "EunuchCouncil", targets: ["EunuchCouncil"])
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI", from: "0.4.5"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "2.13.0"),
    ],
    targets: [
        .target(
            name: "EunuchCouncil",
            dependencies: []
        ),
        .executableTarget(
            name: "EunuchCouncilServer",
            dependencies: [
                "EunuchCouncil",
                "OpenAI",
                .product(name: "Hummingbird", package: "hummingbird"),
            ]
        ),
    ]
)
