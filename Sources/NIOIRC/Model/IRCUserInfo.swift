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

public struct IRCUserInfo : Equatable {
  
  public let username   : String
  public let usermask   : IRCUserMode?
  public let hostname   : String?
  public let servername : String?
  public let realname   : String
  
  public init(username: String, usermask: IRCUserMode, realname: String) {
    self.username   = username
    self.usermask   = usermask
    self.realname   = realname
    self.hostname   = nil
    self.servername = nil
  }
  public init(username: String, hostname: String, servername: String,
              realname: String)
  {
    self.username   = username
    self.hostname   = hostname
    self.servername = servername
    self.realname   = realname
    self.usermask   = nil
  }

  public static func ==(lhs: IRCUserInfo, rhs: IRCUserInfo) -> Bool {
    if lhs.username   != rhs.username   { return false }
    if lhs.realname   != rhs.realname   { return false }
    if lhs.usermask   != rhs.usermask   { return false }
    if lhs.servername != rhs.servername { return false }
    if lhs.hostname   != rhs.hostname   { return false }
    return true
  }
}

extension IRCUserInfo : CustomStringConvertible {
  
  public var description : String {
    var ms = "<IRCUserInfo: \(username)"
    if let v = usermask   { ms += " mask=\(v)" }
    if let v = hostname   { ms += " host=\(v)" }
    if let v = servername { ms += " srv=\(v)" }
    ms += " '\(realname)'"
    ms += ">"
    return ms
  }
  
}
