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

/**
 * Dispatches incoming IRCMessage's to protocol methods.
 *
 * This has a main entry point `irc_msgSend` which takes an `IRCMessage` and
 * then calls the respective protocol functions matching the command of the
 * message.
 *
 * If a dispatcher doesn't implement a method, the
 * `IRCDispatcherError.doesNotRespondTo`
 * error is thrown.
 *
 * Note: Implementors *can* re-implement `irc_msgSend` and still access the
 *       default implementation by calling `irc_defaultMsgSend`. Which contains
 *       the actual dispatcher implementation.
 */
public protocol IRCDispatcher {
  // TODO: Improve this, I don't like anything about this except the dispatcher
  //       name :->
  
  // MARK: - Dispatching Function

  func irc_msgSend(_ message: IRCMessage) throws
  
  // MARK: - Implementations
  
  func doPing      (_ server   : String,
                    server2    : String?)            throws
  func doCAP       (_ cmd      : IRCCommand.CAPSubCommand,
                    _ capIDs   : [ String ])         throws
  
  func doNick      (_ nick     : IRCNickName)        throws
  func doUserInfo  (_ info     : IRCUserInfo)        throws
  func doModeGet   (nick       : IRCNickName)        throws
  func doModeGet   (channel    : IRCChannelName)     throws
  func doMode      (nick       : IRCNickName,
                    add        : IRCUserMode,
                    remove     : IRCUserMode)        throws
  
  func doWhoIs     (server     : String?,
                    usermasks  : [ String ])         throws
  func doWho       (mask       : String?, operatorsOnly opOnly: Bool) throws

  func doJoin      (_ channels : [ IRCChannelName ]) throws
  func doPart      (_ channels : [ IRCChannelName ],
                    message    : String?)            throws
  func doPartAll   ()                                throws
  func doGetBanMask(_ channel  : IRCChannelName)     throws

  func doNotice    (recipients : [ IRCMessageRecipient ],
                    message    : String) throws
  func doMessage   (sender     : IRCUserID?,
                    recipients : [ IRCMessageRecipient ],
                    message    : String) throws

  func doIsOnline  (_ nicks    : [ IRCNickName ]) throws
  func doList      (_ channels : [ IRCChannelName ]?,
                    _ target   : String?)         throws
  
  func doQuit      (_ message  : String?) throws
}

public enum IRCDispatcherError : Swift.Error {
  
  case doesNotRespondTo(IRCMessage)
  
  case nicknameInUse(IRCNickName)
  case noSuchNick   (IRCNickName)
  case noSuchChannel(IRCChannelName)
  case alreadyRegistered
  case notRegistered
  case cantChangeModeForOtherUsers
}

public extension IRCDispatcher {

  func irc_msgSend(_ message: IRCMessage) throws {
    try irc_defaultMsgSend(message)
  }

  func irc_defaultMsgSend(_ message: IRCMessage) throws {
    do {
      switch message.command {
        
        case .PING(let server, let server2):
          try doPing(server, server2: server2)
        
        case .PRIVMSG(let recipients, let payload):
          let sender = message.origin != nil
                     ? IRCUserID(message.origin!) : nil
          try doMessage(sender: sender,
                        recipients: recipients, message: payload)
        case .NOTICE(let recipients, let message):
          try doNotice(recipients: recipients, message: message)
        
        case .NICK   (let nickName):           try doNick    (nickName)
        case .USER   (let info):               try doUserInfo(info)
        case .ISON   (let nicks):              try doIsOnline(nicks)
        case .MODEGET(let nickName):           try doModeGet (nick: nickName)
        case .CAP    (let subcmd, let capIDs): try doCAP     (subcmd, capIDs)
        case .QUIT   (let message):            try doQuit    (message)
        
        case .CHANNELMODE_GET(let channelName):
          try doModeGet(channel: channelName)
        case .CHANNELMODE_GET_BANMASK(let channelName):
          try doGetBanMask(channelName)
        
        case .MODE(let nickName, let add, let remove):
          try doMode(nick: nickName, add: add, remove: remove)
        
        case .WHOIS(let server, let masks):
          try doWhoIs(server: server, usermasks: masks)
        
        case .WHO(let mask, let opOnly):
          try doWho(mask: mask, operatorsOnly: opOnly)
        
        case .JOIN(let channels, _): try doJoin(channels)
        case .JOIN0:                 try doPartAll()
        
        case .PART(let channels, let message):
          try doPart(channels, message: message)
        
        case .LIST(let channels, let target):
          try doList(channels, target)
        
        default:
          throw IRCDispatcherError.doesNotRespondTo(message)
      }
    }
    catch let error as InternalDispatchError {
      switch error {
        case .notImplemented:
          throw IRCDispatcherError.doesNotRespondTo(message)
      }
    }
    catch {
      throw error
    }
  }
}

fileprivate enum InternalDispatchError : Swift.Error {
  case notImplemented(function: String)
}

public extension IRCDispatcher {
  
  func doPing(_ server: String, server2: String?) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doCAP(_ cmd: IRCCommand.CAPSubCommand, _ capIDs: [ String ]) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }

  func doNick(_ nick: IRCNickName) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doUserInfo(_ info: IRCUserInfo) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doModeGet(nick: IRCNickName) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doModeGet(channel: IRCChannelName) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doMode(nick: IRCNickName, add: IRCUserMode, remove: IRCUserMode) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }

  func doWhoIs(server: String?, usermasks: [ String ]) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doWho(mask: String?, operatorsOnly opOnly: Bool) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }

  func doJoin(_ channels: [ IRCChannelName ]) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doPart(_ channels: [ IRCChannelName ], message: String?) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doPartAll() throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doGetBanMask(_ channel: IRCChannelName) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }

  func doNotice(recipients: [ IRCMessageRecipient ], message: String) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doMessage(sender: IRCUserID?, recipients: [ IRCMessageRecipient ],
                 message: String) throws
  {
    throw InternalDispatchError.notImplemented(function: #function)
  }

  func doIsOnline(_ nicks: [ IRCNickName ]) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
  func doList(_ channels : [ IRCChannelName ]?, _ target: String?) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }

  func doQuit(_ message: String?) throws {
    throw InternalDispatchError.notImplemented(function: #function)
  }
}
