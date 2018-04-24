//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-nio-irc open source project
//
// Copyright (c) 2018 ZeeZide GmbH. and the swift-nio-irc project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIOIRC project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO

public let DefaultIRCPort = 6667

/**
 * Protocol handler for IRC
 *
 * The IRC protocol is specified in RFC 2812, which updates RFC 1459. However,
 * servers don't usually adhere to the specs :->
 *
 * Samples:
 *
 *     NICK noze
 *     USER noze 0 * :Noze io
 *     :noze JOIN :#nozechannel
 *     :cherryh.freenode.net 366 helge99 #GNUstep :End of /NAMES list.
 *
 * Basic syntax:
 *
 *     [':' SOURCE]? ' ' COMMAND [' ' ARGS]? [' :' LAST-ARG]?
 *
 */
open class IRCChannelHandler : ChannelDuplexHandler {

  public typealias InboundErr  = IRCParserError
  
  public typealias InboundIn   = ByteBuffer
  public typealias InboundOut  = IRCMessage
  
  public typealias OutboundIn  = IRCMessage
  public typealias OutboundOut = ByteBuffer

  public init() {}
  
  open func channelActive(ctx: ChannelHandlerContext) {
    ctx.fireChannelActive()
  }
  open func channelInactive(ctx: ChannelHandlerContext) {
    ctx.fireChannelInactive()
  }

  
  // MARK: - Reading
  
  var parser = IRCMessageParser()
  
  open func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
    let buffer = self.unwrapInboundIn(data)
    
    parser.feed(buffer) { error, message in
      if let message = message {
        channelRead(ctx: ctx, value: message)
      }
      if let error = error {
        ctx.fireErrorCaught(error)
      }
    }
  }
  
  open func channelRead(ctx: ChannelHandlerContext, value: InboundOut) {
    ctx.fireChannelRead(self.wrapInboundOut(value))
  }
  
  open func errorCaught(ctx: ChannelHandlerContext, error: Swift.Error) {
    ctx.fireErrorCaught(InboundErr.transportError(error))
  }

  
  // MARK: - Writing
  
  public func write(ctx: ChannelHandlerContext, data: NIOAny,
                    promise: EventLoopPromise<Void>?)
  {
    let message : OutboundIn = self.unwrapOutboundIn(data)
    write(ctx: ctx, value: message, promise: promise)
  }
  
  public final func write(ctx: ChannelHandlerContext, value: IRCMessage,
                          promise: EventLoopPromise<Void>?)
  {
    var buffer = ctx.channel.allocator.buffer(capacity: 200)
    encode(value: value, target: value.target, into: &buffer)
    
    ctx.write(NIOAny(buffer), promise: promise)
  }
  
  func encode(value: IRCMessage, target: String?,
              into buffer: inout ByteBuffer)
  {
    let cColon : UInt8 = 58
    let cSpace : UInt8 = 32
    let cStar  : UInt8 = 42
    let cCR    : UInt8 = 13
    let cLF    : UInt8 = 10

    if let origin = value.origin, !origin.isEmpty {
      buffer.write(integer : cColon)
      buffer.write(string  : origin)
      buffer.write(integer : cSpace)
    }
    
    buffer.write(string: value.command.commandAsString)
    
    if let s = target {
      buffer.write(integer : cSpace)
      buffer.write(string  : s)
    }
    
    switch value.command {
      case .PING(let s, let s2), .PONG(let s, let s2):
        if let s2 = s2 {
          buffer.write(integer : cSpace)
          buffer.write(string  : s)
          buffer.writeLastArgument(s2)
        }
        else {
          buffer.writeLastArgument(s)
        }
      
      case .QUIT(.some(let v)):
        buffer.writeLastArgument(v)
      
      case .NICK(let v), .MODEGET(let v):
        buffer.write(integer : cSpace)
        buffer.write(string  : v.stringValue)
      
      case .MODE(let nick, let add, let remove):
        buffer.write(integer : cSpace)
        buffer.write(string  : nick.stringValue)
        
        let adds = add   .stringValue.map { "+\($0)" }
        let rems = remove.stringValue.map { "-\($0)" }
        if adds.isEmpty && rems.isEmpty {
          buffer.writeLastArgument("")
        }
        else {
          buffer.writeArguments(adds + rems, useLast: true)
        }

      case .CHANNELMODE_GET(let v):
        buffer.write(integer : cSpace)
        buffer.write(string  : v.stringValue)
      
      case .CHANNELMODE_GET_BANMASK(let v):
        buffer.write(integer : cSpace)
        buffer.write(integer : UInt8(98)) // 'b'
        buffer.write(integer : cSpace)
        buffer.write(string  : v.stringValue)

      case .CHANNELMODE(let channel, let add, let remove):
        buffer.write(integer : cSpace)
        buffer.write(string  : channel.stringValue)
        
        let adds = add   .stringValue.map { "+\($0)" }
        let rems = remove.stringValue.map { "-\($0)" }
        buffer.writeArguments(adds + rems, useLast: true)
      
      case .USER(let userInfo):
        buffer.write(integer         : cSpace)
        buffer.write(string          : userInfo.username)
        if let mask = userInfo.usermask {
          buffer.write(integer         : cSpace)
          buffer.write(integerAsString : Int(mask.maskValue))
          buffer.write(integer         : cSpace)
          buffer.write(integer         : cStar)
        }
        else {
          buffer.write(integer : cSpace)
          buffer.write(string  : userInfo.hostname ?? "*")
          buffer.write(integer : cSpace)
          buffer.write(string  : userInfo.servername ?? "*")
        }
        buffer.writeLastArgument(userInfo.realname)

      case .QUIT(.none):
        break
      
      case .ISON(let nicks):
        buffer.writeArguments(nicks.lazy.map { $0.stringValue })
      
      case .JOIN0:
        buffer.write(string: " *")
      
      case .JOIN(let channels, let keys):
        buffer.writeCSVArgument(channels.lazy.map { $0.stringValue })
        if let keys = keys { buffer.writeCSVArgument(keys) }
      
      case .PART(let channels, let message):
        buffer.writeCSVArgument(channels.lazy.map { $0.stringValue })
        if let message = message { buffer.writeLastArgument(message) }
      
      case .LIST(let channels, let target):
        if let channels = channels {
          buffer.writeCSVArgument(channels.lazy.map { $0.stringValue })
        }
        else { buffer.write(string: " *")}
        if let target = target { buffer.writeLastArgument(target) }
      
      case .PRIVMSG(let recipients, let message),
           .NOTICE (let recipients, let message):
        buffer.writeCSVArgument(recipients.lazy.map { $0.stringValue })
        buffer.writeLastArgument(message)
      
      case .CAP(let subcmd, let capIDs):
        buffer.write(integer : cSpace)
        buffer.write(string  : subcmd.commandAsString)
        buffer.writeLastArgument(capIDs.joined(separator: " "))

      case .WHOIS(let target, let masks):
        if let target = target {
          buffer.write(integer : cSpace)
          buffer.write(string  : target)
        }
        buffer.write(integer : cSpace)
        buffer.write(string  : masks.joined(separator: ","))

      case .WHO(let mask, let opOnly):
        if let mask = mask {
          buffer.write(integer : cSpace)
          buffer.write(string  : mask)
          if opOnly {
            buffer.write(integer : cSpace)
            buffer.write(integer : UInt8(111)) // o
          }
        }

      case .otherCommand(_, let args),
           .otherNumeric(_, let args),
           .numeric     (_, let args):
        buffer.writeArguments(args, useLast: true)
    }
    
    buffer.write(integer: cCR)
    buffer.write(integer: cLF)
  }
}

extension ByteBuffer {
  
  mutating func writeCSVArgument<T: Sequence>(_ args: T)
                           where T.Element == String
  {
    let cSpace : UInt8 = 32
    let cComma : UInt8 = 44
    
    write(integer : cSpace)
    
    var isFirst = true
    for arg in args {
      if isFirst { isFirst = false }
      else { write(integer: cComma) }
      write(string: arg)
    }
  }
  mutating func writeArguments<T: Sequence>(_ args: T)
                         where T.Element == String
  {
    let cSpace : UInt8 = 32
    
    for arg in args {
      write(integer : cSpace)
      write(string  : arg)
    }
  }
  mutating func writeArguments<T: Collection>(_ args: T, useLast: Bool = false)
                         where T.Element == String
  {
    let cSpace : UInt8 = 32
    
    guard !args.isEmpty else { return }
    
    for arg in args.dropLast() {
      write(integer : cSpace)
      write(string  : arg)
    }
    
    let lastIdx = args.index(args.startIndex, offsetBy: args.count - 1)
    return writeLastArgument(args[lastIdx])
  }

  mutating func writeLastArgument(_ s: String) {
    let cSpace : UInt8 = 32
    let cColon : UInt8 = 58
    
    write(integer : cSpace)
    write(integer : cColon)
    write(string  : s)
  }
  
}
