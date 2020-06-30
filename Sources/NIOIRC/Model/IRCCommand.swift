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

import struct Foundation.Data

public enum IRCCommand {
  
  case NICK(IRCNickName)
  case USER(IRCUserInfo)
  
  case ISON([ IRCNickName ])
  
  case QUIT(String?)
  case PING(server: String, server2: String?)
  case PONG(server: String, server2: String?)
  
  case JOIN(channels: [ IRCChannelName ], keys: [ String ]?)
  
  /// JOIN-0 is actually "unsubscribe all channels"
  case JOIN0
  
  /// Unsubscribe the given channels.
  case PART(channels: [ IRCChannelName ],  message: String?)
  
  case LIST(channels: [ IRCChannelName ]?, target: String?)
  
  case PRIVMSG([ IRCMessageRecipient ], String)
  case NOTICE ([ IRCMessageRecipient ], String)

  case MODE(IRCNickName, add: IRCUserMode, remove: IRCUserMode)
  case MODEGET(IRCNickName)
  case CHANNELMODE(IRCChannelName, add: IRCChannelMode, remove: IRCChannelMode)
  case CHANNELMODE_GET(IRCChannelName)
  case CHANNELMODE_GET_BANMASK(IRCChannelName)

  case WHOIS(server: String?, usermasks: [ String ])
  case WHO(usermask: String?, onlyOperators: Bool)

  case numeric     (IRCCommandCode, [ String ])
  case otherCommand(String,         [ String ])
  case otherNumeric(Int,            [ String ])
  
  
  // MARK: - IRCv3.net
  
  public enum CAPSubCommand : String {
    case LS, LIST, REQ, ACK, NAK, END
    
    public var commandAsString : String { return rawValue }
  }
  case CAP(CAPSubCommand, [ String ])
}


// MARK: - Description

extension IRCCommand : CustomStringConvertible {
  
  public var commandAsString : String {
    switch self {
      case .NICK:           return "NICK"
      case .USER:           return "USER"
      case .ISON:           return "ISON"
      case .QUIT:           return "QUIT"
      case .PING:           return "PING"
      case .PONG:           return "PONG"
      case .JOIN, .JOIN0:   return "JOIN"
      case .PART:           return "PART"
      case .LIST:           return "LIST"
      case .PRIVMSG:        return "PRIVMSG"
      case .NOTICE:         return "NOTICE"
      case .CAP:            return "CAP"
      case .MODE, .MODEGET: return "MODE"
      case .WHOIS:          return "WHOIS"
      case .WHO:            return "WHO"
      case .CHANNELMODE:    return "MODE"
      case .CHANNELMODE_GET, .CHANNELMODE_GET_BANMASK: return "MODE"

      case .otherCommand(let cmd, _): return cmd
      case .otherNumeric(let cmd, _):
        let s = String(cmd)
        if s.count >= 3 { return s }
        return String(repeating: "0", count: 3 - s.count) + s
      case .numeric(let cmd, _):
        let s = String(cmd.rawValue)
        if s.count >= 3 { return s }
        return String(repeating: "0", count: 3 - s.count) + s
    }
  }
  
  public var arguments : [ String ] {
    switch self {
      case .NICK(let nick): return [ nick.stringValue ]
      case .USER(let info):
        if let usermask = info.usermask {
          return [ info.username, usermask.stringValue, "*", info.realname ]
        }
        else {
          return [ info.username,
                   info.hostname ?? info.usermask?.stringValue ?? "*",
                   info.servername ?? "*",
                   info.realname ]
        }

      case .ISON(let nicks): return nicks.map { $0.stringValue }
      
      case .QUIT(.none):                          return []
      case .QUIT(.some(let message)):             return [ message ]
      case .PING(let server, .none):              return [ server ]
      case .PONG(let server, .none):              return [ server ]
      case .PING(let server, .some(let server2)): return [ server, server2 ]
      case .PONG(let server, .some(let server2)): return [ server, server2 ]
      
      case .JOIN(let channels, .none):
        return [ channels.map { $0.stringValue }.joined(separator: ",") ]
      case .JOIN(let channels, .some(let keys)):
        return [ channels.map { $0.stringValue }.joined(separator: ","),
                 keys.joined(separator: ",")]
      
      case .JOIN0: return [ "0" ]
      
      case .PART(let channels, .none):
        return [ channels.map { $0.stringValue }.joined(separator: ",") ]
      case .PART(let channels, .some(let m)):
        return [ channels.map { $0.stringValue }.joined(separator: ","), m ]

      case .LIST(let channels, .none):
        guard let channels = channels else { return [] }
        return [ channels.map { $0.stringValue }.joined(separator: ",") ]
      case .LIST(let channels, .some(let target)):
        return [ (channels ?? []).map { $0.stringValue }.joined(separator: ","),
                 target ]

      case .PRIVMSG(let recipients, let m), .NOTICE (let recipients, let m):
        return [ recipients.map { $0.stringValue }.joined(separator: ","), m ]

      case .MODE(let name, let add, let remove):
        if add.isEmpty && remove.isEmpty { return [ name.stringValue, "" ] }
        else if !add.isEmpty && !remove.isEmpty {
          return [ name.stringValue,
                   "+" + add.stringValue, "-" + remove.stringValue ]
        }
        else if !remove.isEmpty {
          return [ name.stringValue, "-" + remove.stringValue ]
        }
        else {
          return [ name.stringValue, "+" + add.stringValue ]
        }
      case .CHANNELMODE(let name, let add, let remove):
        if add.isEmpty && remove.isEmpty { return [ name.stringValue, "" ] }
        else if !add.isEmpty && !remove.isEmpty {
          return [ name.stringValue,
                   "+" + add.stringValue, "-" + remove.stringValue ]
        }
        else if !remove.isEmpty {
          return [ name.stringValue, "-" + remove.stringValue ]
        }
        else {
          return [ name.stringValue, "+" + add.stringValue ]
        }
      case .MODEGET(let name): return [ name.stringValue ]
      case .CHANNELMODE_GET(let name), .CHANNELMODE_GET_BANMASK(let name):
        return [ name.stringValue ]
      
      case .WHOIS(.some(let server), let usermasks):
        return [ server, usermasks.joined(separator: ",")]
      case .WHOIS(.none, let usermasks):
        return [ usermasks.joined(separator: ",") ]
      
      case .WHO(.none, _):                   return []
      case .WHO(.some(let usermask), false): return [ usermask ]
      case .WHO(.some(let usermask), true):  return [ usermask, "o" ]

      case .numeric     (_, let args),
           .otherCommand(_, let args),
           .otherNumeric(_, let args): return args
      
      default: // TBD: which case do we miss???
        fatalError("unexpected case \(self)")
    }
  }
  
  public var description : String {
    switch self {
      case .PING(let server, let server2), .PONG(let server, let server2):
        if let server2 = server2 {
          return "\(commandAsString) '\(server)' '\(server2)'"
        }
        else {
          return "\(commandAsString) '\(server)'"
        }
      
      case .QUIT(.some(let v)): return "QUIT '\(v)'"
      case .QUIT(.none): return "QUIT"
      case .NICK(let v): return "NICK \(v)"
      case .USER(let v): return "USER \(v)"
      case .ISON(let v):
        let nicks = v.map { $0.stringValue}
        return "ISON \(nicks.joined(separator: ","))"

      case .MODEGET(let nick):
        return "MODE \(nick)"
      case .MODE(let nick, let add, let remove):
        var s = "MODE \(nick)"
        if !add   .isEmpty { s += " +\(add   .stringValue)" }
        if !remove.isEmpty { s += " -\(remove.stringValue)" }
        return s

      case .CHANNELMODE_GET(let v):         return "MODE \(v)"
      case .CHANNELMODE_GET_BANMASK(let v): return "MODE b \(v)"
      case .CHANNELMODE(let nick, let add, let remove):
        var s = "MODE \(nick)"
        if !add   .isEmpty { s += " +\(add   .stringValue)" }
        if !remove.isEmpty { s += " -\(remove.stringValue)" }
        return s

      case .JOIN0: return "JOIN0"
      
      case .JOIN(let channels, .none):
        let names = channels.map { $0.stringValue}
        return "JOIN \(names.joined(separator: ","))"
      
      case .JOIN(let channels, .some(let keys)):
        let names = channels.map { $0.stringValue}
        return "JOIN \(names.joined(separator: ","))"
             + " keys: \(keys.joined(separator: ","))"

      case .PART(let channels, .none):
        let names = channels.map { $0.stringValue}
        return "PART \(names.joined(separator: ","))"
      
      case .PART(let channels, .some(let message)):
        let names = channels.map { $0.stringValue}
        return "PART \(names.joined(separator: ",")) '\(message)'"
      
      case .LIST(.none, .none):             return "LIST *"
      case .LIST(.none, .some(let target)): return "LIST * @\(target)"
      
      case .LIST(.some(let channels), .none):
        let names = channels.map { $0.stringValue}
        return "LIST \(names.joined(separator: ",") )"
      
      case .LIST(.some(let channels), .some(let target)):
        let names = channels.map { $0.stringValue}
        return "LIST @\(target) \(names.joined(separator: ",") )"
      
      case .PRIVMSG(let recipients, let message):
        let to = recipients.map { $0.description }
        return "PRIVMSG \(to.joined(separator: ",")) '\(message)'"
      case .NOTICE (let recipients, let message):
        let to = recipients.map { $0.description }
        return "NOTICE \(to.joined(separator: ",")) '\(message)'"
      
      case .CAP(let subcmd, let capIDs):
        return "CAP \(subcmd) \(capIDs.joined(separator: ","))"
      case .WHOIS(.none, let masks):
        return "WHOIS \(masks.joined(separator: ","))"
      case .WHOIS(.some(let target), let masks):
        return "WHOIS @\(target) \(masks.joined(separator: ","))"
      case .WHO(.none, _):
        return "WHO"
      case .WHO(.some(let mask), let opOnly):
        return "WHO \(mask)\(opOnly ? " o" : "")"

      case .otherCommand(let cmd, let args):
        return "<IRCCmd: \(cmd) args=\(args.joined(separator: ","))>"
      case .otherNumeric(let cmd, let args):
        return "<IRCCmd: \(cmd) args=\(args.joined(separator: ","))>"
      case .numeric(let cmd, let args):
        return "<IRCCmd: \(cmd.rawValue) args=\(args.joined(separator: ","))>"
    }
  }
  
}
