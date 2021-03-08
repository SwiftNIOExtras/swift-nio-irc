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

/**
 * An IRC channel name
 *
 * Channel names are case-insensitive!
 *
 * Strings beginning with a type code (see [IRC-CHAN]):
 * - &, #, +, !
 *
 * - length: max 50
 * - shall not contain spaces
 * - shall not contain ASCII 7 (^G)
 * - shall not contain a ','
 */
public struct IRCChannelName : Hashable, CustomStringConvertible {
  
  public typealias StringLiteralType = String
  
  @usableFromInline let storage    : String
  @usableFromInline let normalized : String

  @inlinable
  public init?(_ s: String) {
    guard IRCChannelName.validate(string: s) else { return nil }
    storage    = s
    normalized = s.ircLowercased()
  }
  
  @inlinable
  public var stringValue : String { return storage }
  
  @inlinable
  public func hash(into hasher: inout Hasher) {
    normalized.hash(into: &hasher)
  }
  
  @inlinable
  public static func ==(lhs: IRCChannelName, rhs: IRCChannelName) -> Bool {
    return lhs.normalized == rhs.normalized
  }
  
  @inlinable
  public var description : String { return stringValue }
  
  @inlinable
  public static func validate(string: String) -> Bool {
    guard string.count > 1 && string.count <= 50 else { return false }
    
    switch string.first! {
      case "&", "#", "+", "!": break
      default: return false
    }
    
    func isValidCharacter(_ c: UInt8) -> Bool {
      return c != 7 && c != 32 && c != 44
    }
    guard !string.utf8.contains(where: { !isValidCharacter($0) }) else {
      return false
    }
    
    // TODO: RFC 2812 2.3.1

    return true
  }
}
