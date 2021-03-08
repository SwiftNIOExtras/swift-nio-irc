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

public extension IRCCommand {
  
  /**
   * This initializer creates `IRCCommand` values from String command names and
   * string arguments (as parsed by the `IRCMessageParser`).
   *
   * The parser validates the argument counts etc and throws exceptions on
   * unexpected input.
   */
  @inlinable
  init(_ command: String, arguments: [ String ]) throws {
    typealias Error = IRCParserError
    
    func expect(argc: Int) throws {
      guard argc == arguments.count else {
        throw Error.invalidArgumentCount(command: command,
                                         count: arguments.count, expected: argc)
      }
    }
    func expect(min: Int? = nil, max: Int? = nil) throws {
      if let max = max {
        guard arguments.count <= max else {
          throw Error.invalidArgumentCount(command: command,
                                           count: arguments.count,
                                           expected: max)
        }
      }
      if let min = min {
        guard arguments.count >= min else {
          throw Error.invalidArgumentCount(command: command,
                                           count: arguments.count,
                                           expected: min)
        }
      }
    }
    
    func splitChannelsString(_ s: String) throws -> [ IRCChannelName ] {
      return try arguments[0].split(separator: ",").map {
        guard let n = IRCChannelName(String($0)) else {
          throw Error.invalidChannelName(String($0))
        }
        return n
      }
    }
    func splitRecipientString(_ s: String) throws -> [ IRCMessageRecipient ] {
      return try arguments[0].split(separator: ",").map {
        guard let n = IRCMessageRecipient(String($0)) else {
          throw Error.invalidMessageTarget(String($0))
        }
        return n
      }
    }

    switch command.uppercased() {
      case "QUIT": try expect(max:  1); self = .QUIT(arguments.first)
      
      case "PING":
        try expect(min: 1, max: 2)
        self = .PING(server: arguments[0],
                     server2: arguments.count > 1 ? arguments[1] : nil)
      case "PONG":
        try expect(min: 1, max: 2)
        self = .PONG(server: arguments[0],
                     server2: arguments.count > 1 ? arguments[1] : nil)

      case "NICK":
        try expect(argc: 1)
        guard let nick = IRCNickName(arguments[0]) else {
          throw Error.invalidNickName(arguments[0])
        }
        self = .NICK(nick)
      
      case "MODE":
        try expect(min: 1)
        guard let recipient = IRCMessageRecipient(arguments[0]) else {
          throw Error.invalidMessageTarget(arguments[0])
        }
        
        switch recipient {
          case .everything:
            throw Error.invalidMessageTarget(arguments[0])
          
          case .nickname(let nick):
            if arguments.count > 1 {
              var add    = IRCUserMode()
              var remove = IRCUserMode()
              for arg in arguments.dropFirst() {
                var isAdd = true
                for c in arg {
                  if      c == "+" { isAdd = true  }
                  else if c == "-" { isAdd = false }
                  else if let mode = IRCUserMode(String(c)) {
                    if isAdd { add   .insert(mode) }
                    else     { remove.insert(mode) }
                  }
                  else {
                    // else: warn? throw?
                    print("IRCParser: unexpected IRC mode: \(c) \(arg)")
                  }
                }
              }
              self = .MODE(nick, add: add, remove: remove)
            }
            else {
              self = .MODEGET(nick)
            }
          
          case .channel(let channelName):
            if arguments.count > 1 {
              var add    = IRCChannelMode()
              var remove = IRCChannelMode()
              for arg in arguments.dropFirst() {
                var isAdd = true
                for c in arg {
                  if      c == "+" { isAdd = true  }
                  else if c == "-" { isAdd = false }
                  else if let mode = IRCChannelMode(String(c)) {
                    if isAdd { add   .insert(mode) }
                    else     { remove.insert(mode) }
                  }
                  else {
                    // else: warn? throw?
                    print("IRCParser: unexpected IRC mode: \(c) \(arg)")
                  }
                }
              }
              if add == IRCChannelMode.banMask && remove.isEmpty {
                self = .CHANNELMODE_GET_BANMASK(channelName)
              }
              else {
                self = .CHANNELMODE(channelName, add: add, remove: remove)
              }
            }
            else {
              self = .CHANNELMODE_GET(channelName)
            }
        }

      case "USER":
        // RFC 1459 <username> <hostname> <servername> <realname>
        // RFC 2812 <username> <mode>     <unused>     <realname>
        try expect(argc: 4)
        if let mask = UInt16(arguments[1]) {
          self = .USER(IRCUserInfo(username : arguments[0],
                                   usermask : IRCUserMode(rawValue: mask),
                                   realname : arguments[3]))
        }
        else {
          self = .USER(IRCUserInfo(username   : arguments[0],
                                   hostname   : arguments[1],
                                   servername : arguments[2],
                                   realname   : arguments[3]))
        }
      
      
      case "JOIN":
        try expect(min: 1, max: 2)
        if arguments[0] == "0" {
          self = .JOIN0
        }
        else {
          let channels = try splitChannelsString(arguments[0])
          let keys = arguments.count > 1
                   ? arguments[1].split(separator: ",").map(String.init)
                   : nil
          self = .JOIN(channels: channels, keys: keys)
        }
      
      case "PART":
        try expect(min: 1, max: 2)
        let channels = try splitChannelsString(arguments[0])
        self = .PART(channels: channels,
                     message: arguments.count > 1 ? arguments[1] : nil)
      
      case "LIST":
        try expect(max: 2)
        
        let channels = arguments.count > 0
                     ? try splitChannelsString(arguments[0]) : nil
        let target   = arguments.count > 1 ? arguments[1] : nil
        self = .LIST(channels: channels, target: target)
      
      case "ISON":
        try expect(min: 1)
        var nicks = [ IRCNickName ]()
        for arg in arguments {
          nicks += try arg.split(separator: " ").map(String.init).map {
            guard let nick = IRCNickName($0) else {
              throw Error.invalidNickName($0)
            }
            return nick
          }
        }
        self = .ISON(nicks)
      
      case "PRIVMSG":
        try expect(argc: 2)
        let targets = try splitRecipientString(arguments[0])
        self = .PRIVMSG(targets, arguments[1])
      
      case "NOTICE":
        try expect(argc: 2)
        let targets = try splitRecipientString(arguments[0])
        self = .NOTICE(targets, arguments[1])
      
      case "CAP":
        try expect(min: 1, max: 2)
        guard let subcmd = CAPSubCommand(rawValue: arguments[0]) else {
          throw IRCParserError.invalidCAPCommand(arguments[0])
        }
        let capIDs = arguments.count > 1
                   ? arguments[1].components(separatedBy: " ")
                   : []
        self = .CAP(subcmd, capIDs)
      
      case "WHOIS":
        try expect(min: 1, max: 2)
        let maskArg = arguments.count == 1 ? arguments[0] : arguments[1]
        let masks   = maskArg.split(separator: ",").map(String.init)
        self = .WHOIS(server: arguments.count == 1 ? nil : arguments[0],
                      usermasks: Array(masks))
      
      case "WHO":
        try expect(max: 2)
        switch arguments.count {
          case 0: self = .WHO(usermask: nil, onlyOperators: false)
          case 1: self = .WHO(usermask: arguments[0], onlyOperators: false)
          case 2: self = .WHO(usermask: arguments[0],
                              onlyOperators: arguments[1] == "o")
          default: fatalError("unexpected argument count \(arguments.count)")
        }

      default:
        self = .otherCommand(command.uppercased(), arguments)
    }
  }
  
  /**
   * This initializer creates `IRCCommand` values from numeric commands and
   * string arguments (as parsed by the `IRCMessageParser`).
   *
   * The parser validates the argument counts etc and throws exceptions on
   * unexpected input.
   */
  @inlinable
  init(_ v: Int, arguments: [ String ]) throws {
    if let code = IRCCommandCode(rawValue: v) {
      self = .numeric(code, arguments)
    }
    else {
      self = .otherNumeric(v, arguments)
    }
  }

  /**
   * This initializer creates `IRCCommand` values from String command names and
   * string arguments (as parsed by the `IRCMessageParser`).
   *
   * The parser validates the argument counts etc and throws exceptions on
   * unexpected input.
   */
  @inlinable
  init(_ s: String, _ arguments: String...) throws {
    try self.init(s, arguments: arguments)
  }
  
  /**
   * This initializer creates `IRCCommand` values from numeric commands and
   * string arguments (as parsed by the `IRCMessageParser`).
   *
   * The parser validates the argument counts etc and throws exceptions on
   * unexpected input.
   */
  @inlinable
  init(_ v: Int, _ arguments: String...) throws {
    try self.init(v, arguments: arguments)
  }
}
