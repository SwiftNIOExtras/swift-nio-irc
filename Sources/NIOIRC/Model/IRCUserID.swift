//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-nio-irc open source project
//
// Copyright (c) 2018-2020 ZeeZide GmbH. and the swift-nio-irc project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIOIRC project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public struct IRCUserID : Hashable, CustomStringConvertible {
  // TBD: is that really called the user-mask? Or more like "fullusername"?
  
  public let nick : IRCNickName
  public let user : String?
  public let host : String?
  
  public init(nick: IRCNickName, user: String? = nil, host: String? = nil) {
    self.nick = nick
    self.user = user
    self.host = host
  }
  
  public init?(_ s: String) {
    if let atIdx = s.firstIndex(of: "@") {
      let hs = s.index(after: atIdx)
      self.host = String(s[hs..<s.endIndex])
      
      let nickString : String
      if let exIdx = s.firstIndex(of: "!") {
        let hs = s.index(after: exIdx)
        self.user = String(s[hs..<atIdx])
        
        nickString = String(s[s.startIndex..<exIdx])
      }
      else {
        self.user = nil
        nickString = String(s[s.startIndex..<atIdx])
      }
      guard let nick = IRCNickName(nickString) else { return nil }
      self.nick = nick
    }
    else {
      guard let nick = IRCNickName(s) else { return nil }
      self.nick = nick
      self.user = nil
      self.host = nil
    }
  }
  
  #if compiler(>=5)
    public func hash(into hasher: inout Hasher) { nick.hash(into: &hasher) }
  #else
    public var hashValue: Int { return nick.hashValue }
  #endif
  
  public static func ==(lhs: IRCUserID, rhs: IRCUserID) -> Bool {
    return lhs.nick == rhs.nick && lhs.user == rhs.user && lhs.host == rhs.host
  }
  
  public var stringValue : String {
    var ms = "\(nick)"
    if let host = host {
      if let user = user { ms += "!\(user)" }
      ms += "@\(host)"
    }
    return ms
  }
  
  public var description: String {
    return stringValue
  }
  
}
