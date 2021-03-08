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

public struct IRCUserMode : OptionSet {
  
  public let rawValue: UInt16
  
  @inlinable
  public init(rawValue: UInt16) {
    self.rawValue = rawValue
  }
  
  public static let receivesWallOps       = IRCUserMode(rawValue: 1 << 2)
  public static let invisible             = IRCUserMode(rawValue: 1 << 3)

  public static let away                  = IRCUserMode(rawValue: 1 << 4)
  public static let restrictedConnection  = IRCUserMode(rawValue: 1 << 5)
  public static let `operator`            = IRCUserMode(rawValue: 1 << 6)
  public static let localOperator         = IRCUserMode(rawValue: 1 << 7)
  public static let receivesServerNotices = IRCUserMode(rawValue: 1 << 8)

  // Freenode
  public static let ignoreUnknown         = IRCUserMode(rawValue: 1 << 9)
  public static let disableForwarding     = IRCUserMode(rawValue: 1 << 10)
  public static let blockUnidentified     = IRCUserMode(rawValue: 1 << 11)
  public static let connectedSecurely     = IRCUserMode(rawValue: 1 << 12)
  
  // UnrealIRCd https://www.unrealircd.org/docs/User_Modes "x"
  public static let hideHostname          = IRCUserMode(rawValue: 1 << 13)

  @inlinable
  public var maskValue : UInt16 { return rawValue }
  
  @inlinable
  public init?(_ string: String) {
    var mask : UInt16 = 0
    for c in string {
      switch c {
        case "w": mask += IRCUserMode.receivesWallOps      .rawValue
        case "i": mask += IRCUserMode.invisible            .rawValue
        case "a": mask += IRCUserMode.away                 .rawValue
        case "r": mask += IRCUserMode.restrictedConnection .rawValue
        case "o": mask += IRCUserMode.operator             .rawValue
        case "O": mask += IRCUserMode.localOperator        .rawValue
        case "s": mask += IRCUserMode.receivesServerNotices.rawValue
        case "g": mask += IRCUserMode.ignoreUnknown        .rawValue
        case "Q": mask += IRCUserMode.disableForwarding    .rawValue
        case "R": mask += IRCUserMode.blockUnidentified    .rawValue
        case "Z": mask += IRCUserMode.connectedSecurely    .rawValue
        case "x": mask += IRCUserMode.hideHostname         .rawValue
        default: return nil
      }
    }

    self.init(rawValue: mask)
  }
  
  @inlinable
  public var stringValue : String {
    var mode = ""
    mode.reserveCapacity(8)
    if contains(.receivesWallOps)       { mode += "w" }
    if contains(.invisible)             { mode += "i" }
    if contains(.away)                  { mode += "a" }
    if contains(.restrictedConnection)  { mode += "r" }
    if contains(.operator)              { mode += "o" }
    if contains(.localOperator)         { mode += "O" }
    if contains(.receivesServerNotices) { mode += "s" }
    if contains(.ignoreUnknown)         { mode += "g" }
    if contains(.disableForwarding)     { mode += "Q" }
    if contains(.blockUnidentified)     { mode += "R" }
    if contains(.connectedSecurely)     { mode += "Z" }
    if contains(.hideHostname)          { mode += "x" }
    return mode
  }
}
