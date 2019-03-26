// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swift-nio-irc",
    products: [
        .library(name: "NIOIRC", targets: [ "NIOIRC" ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", 
                 from: "1.13.2")
    ],
    targets: [
        .target(name: "NIOIRC", dependencies: [ "NIO" ])
    ]
)
