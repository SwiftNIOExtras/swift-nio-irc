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

public enum IRCMessageRecipient : Hashable {
  
  case channel (IRCChannelName)
  case nickname(IRCNickName)
  case everything // Note: this doesn't seem to be spec'ed?!
  
  // TODO:
  // or: user, or user%host, @server, etc
  // or: nickname!user@host
  
  public var hashValue: Int {
    switch self {
      case .channel (let name): return name.hashValue
      case .nickname(let name): return name.hashValue
      case .everything:         return 42
    }
  }
  
  public static func ==(lhs: IRCMessageRecipient, rhs: IRCMessageRecipient)
                  -> Bool
  {
    switch ( lhs, rhs ) {
      case ( .everything,        .everything ):       return true
      case ( .channel (let lhs), .channel (let rhs)): return lhs == rhs
      case ( .nickname(let lhs), .nickname(let rhs)): return lhs == rhs
      default: return false
    }
  }
}

public extension IRCMessageRecipient {
  
  public init?(_ s: String) {
    if s == "*" {
      self = .everything
    }
    else if let channel = IRCChannelName(s) {
      self = .channel(channel)
    }
    else if let nick = IRCNickName(s) {
      self = .nickname(nick)
    }
    else {
      return nil
    }
  }
  
  public var stringValue : String {
    switch self {
      case .channel (let name): return name.stringValue
      case .nickname(let name): return name.stringValue
      case .everything: return "*"
    }
  }
}

extension IRCMessageRecipient : CustomStringConvertible {
  
  public var description : String {
    switch self {
      case .channel (let name): return name.description
      case .nickname(let name): return name.description
      case .everything: return "<IRCRecipient: *>"
    }
  }
}
