// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "swift-nio-irc",
    products: [
        .library(name: "NIOIRC", targets: [ "NIOIRC" ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", 
                 from: "2.0.0")
    ],
    targets: [
        .target(name: "NIOIRC", dependencies: [ "NIO" ])
    ]
)
