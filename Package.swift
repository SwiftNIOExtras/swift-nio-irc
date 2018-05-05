// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "swift-nio-irc",
    products: [
        .library   (name: "NIOIRC", targets: [ "NIOIRC" ]),
        .library   (name: "IRC",    targets: [ "IRC"    ])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", 
                 .branch("master")),
    ],
    targets: [
        .target(name: "NIOIRC", dependencies: [ "NIO"    ]),
        .target(name: "IRC",    dependencies: [ "NIOIRC" ])
    ]
)
