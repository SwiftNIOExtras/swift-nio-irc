# SwiftNIO IRC

SwiftNIO IRC is a Internet Relay Chat 
[protocol implementation](Sources/NIOIRC) for
[SwiftNIO](https://github.com/apple/swift-nio)
and a simple 
[IRC client](Sources/IRC).

NIOIRC is a SwiftNIO port of the
[Noze.io miniirc](https://github.com/NozeIO/Noze.io/tree/master/Samples/miniirc)
example from 2016.


## Importing the module using Swift Package Manager

An example `Package.swift `importing the necessary modules:

```swift
// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "IRCTests",
    dependencies: [
        .package(url: "https://github.com/NozeIO/swift-nio-irc.git",
                 from: "0.5.0")
    ],
    targets: [
        .target(name: "MyProtocolTool",
                dependencies: [ "NIOIRC" ]),
        .target(name: "MyIRCClient",
                dependencies: [ "IRC" ])
    ]
)
```


## Using the SwiftNIO IRC protocol handler

The IRC protocol is implemented as a regular
`ChannelHandler`, similar to `NIOHTTP1`.
It takes incoming `ByteBuffer` data, parses that, and emits `IRCMessage`
items.
Same the other way around, the user writes `IRCReply`
objects, and the handler renders such into `ByteBuffer`s.

To add the IRC handler to a NIO Channel pipeline:

```swift
import NIOIRC

bootstrap.channelInitializer { channel in
    channel.pipeline
        .add(handler: IRCChannelHandler())
        .then { ... }
}
```


### Who

Brought to you by
[ZeeZide](http://zeezide.de).
We like
[feedback](https://twitter.com/ar_institute),
GitHub stars,
cool [contract work](http://zeezide.com/en/services/services.html),
presumably any form of praise you can think of.
