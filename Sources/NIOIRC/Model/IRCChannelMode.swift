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

public struct IRCChannelMode : OptionSet {
  
  public let rawValue: UInt16

  @inlinable
  public init(rawValue: UInt16) {
    self.rawValue = rawValue
  }
  
  public static let channelOperator     = IRCChannelMode(rawValue: 1 << 0)
  public static let `private`           = IRCChannelMode(rawValue: 1 << 1)
  public static let secret              = IRCChannelMode(rawValue: 1 << 2)
  public static let inviteOnly          = IRCChannelMode(rawValue: 1 << 3)
  public static let topicOnlyByOperator = IRCChannelMode(rawValue: 1 << 4)
  public static let noOutsideClients    = IRCChannelMode(rawValue: 1 << 5)
  public static let moderated           = IRCChannelMode(rawValue: 1 << 6)
  public static let userLimit           = IRCChannelMode(rawValue: 1 << 7)
  public static let banMask             = IRCChannelMode(rawValue: 1 << 8)
  public static let speakControl        = IRCChannelMode(rawValue: 1 << 9)
  public static let password            = IRCChannelMode(rawValue: 1 << 10)

  @inlinable
  public var maskValue : UInt16 { return rawValue }
  
  @inlinable
  public init?(_ string: String) {
    var mask : UInt16 = 0
    for c in string {
      switch c {
        case "o": mask += IRCChannelMode.channelOperator.rawValue
        case "p": mask += IRCChannelMode.`private`.rawValue
        case "s": mask += IRCChannelMode.secret.rawValue
        case "i": mask += IRCChannelMode.inviteOnly.rawValue
        case "t": mask += IRCChannelMode.topicOnlyByOperator.rawValue
        case "n": mask += IRCChannelMode.noOutsideClients.rawValue
        case "m": mask += IRCChannelMode.moderated.rawValue
        case "l": mask += IRCChannelMode.userLimit.rawValue
        case "b": mask += IRCChannelMode.banMask.rawValue
        case "v": mask += IRCChannelMode.speakControl.rawValue
        case "k": mask += IRCChannelMode.password.rawValue
        default: return nil
      }
    }

    self.init(rawValue: mask)
  }
  
  @inlinable
  public var stringValue : String {
    var mode = ""
    if contains(.channelOperator)     { mode += "o" }
    if contains(.`private`)           { mode += "p" }
    if contains(.secret)              { mode += "s" }
    if contains(.inviteOnly)          { mode += "i" }
    if contains(.topicOnlyByOperator) { mode += "t" }
    if contains(.noOutsideClients)    { mode += "n" }
    if contains(.moderated)           { mode += "m" }
    if contains(.userLimit)           { mode += "l" }
    if contains(.banMask)             { mode += "b" }
    if contains(.speakControl)        { mode += "v" }
    if contains(.password)            { mode += "k" }
    return mode
  }
}
