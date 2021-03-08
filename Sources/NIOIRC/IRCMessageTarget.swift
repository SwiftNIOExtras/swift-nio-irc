//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-nio-irc open source project
//
// Copyright (c) 2018-2021 ZeeZide GmbH. and the swift-nio-irc project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIOIRC project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct NIO.EventLoopPromise

/**
 * A `IRCMessageTarget` is the reverse to the `IRCMessageDispatcher`.
 *
 * Both the `IRCClient` and the `IRCServer` objects implement this protocol
 * and just its `sendMessages` and `origin` methods.
 *
 * Extensions then provide extra functionality based on this, the PoP way.
 */
public protocol IRCMessageTarget {
  
  var origin : String? { get }
  
  func sendMessages<T: Collection>(_ messages: T,
                                   promise: EventLoopPromise<Void>?)
         where T.Element == IRCMessage
  
}

public extension IRCMessageTarget {

  @inlinable
  func sendMessage(_ message: IRCMessage,
                   promise: EventLoopPromise<Void>? = nil)
  {
    sendMessages([ message ], promise: promise)
  }
}

public extension IRCMessageTarget {
  
  @inlinable
  func sendMessage(_ text: String, to recipients: IRCMessageRecipient...) {
    guard !recipients.isEmpty else { return }
    
    let lines = text.components(separatedBy: "\n")
                    .map { $0.replacingOccurrences(of: "\r", with: "") }
    
    let messages = lines.map {
      IRCMessage(origin: origin, command: .PRIVMSG(recipients, $0))
    }
    sendMessages(messages, promise: nil)
  }
  
  @inlinable
  func sendNotice(_ text: String, to recipients: IRCMessageRecipient...) {
    guard !recipients.isEmpty else { return }
    
    let lines = text.components(separatedBy: "\n")
                    .map { $0.replacingOccurrences(of: "\r", with: "") }

    let messages = lines.map {
      IRCMessage(origin: origin, command: .NOTICE(recipients, $0))
    }
    sendMessages(messages, promise: nil)
  }
  
  @inlinable
  func sendRawReply(_ code: IRCCommandCode, _ args: String...) {
    sendMessage(IRCMessage(origin: origin, command: .numeric(code, args)))
  }
}

