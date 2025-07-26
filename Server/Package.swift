// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EunuchCouncil",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI", from: "0.4.5"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "2.13.0"),
    ],
    targets: [
        .executableTarget(
            name: "EunuchCouncil",
            dependencies: [
                "OpenAI",
                .product(name: "Hummingbird", package: "hummingbird"),
            ]
        ),
    ]
)
