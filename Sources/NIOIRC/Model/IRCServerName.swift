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
 * An IRC server name.
 *
 * Maximum length is 63 characters.
 */
public struct IRCServerName : Hashable {
  
  public typealias StringLiteralType = String
  
  @usableFromInline let storage    : String
  @usableFromInline let normalized : String
  
  @inlinable
  public init?(_ s: String) {
    guard IRCNickName.validate(string: s) else { return nil }
    storage    = s
    normalized = s.ircLowercased()
  }
  
  @inlinable
  public var stringValue : String { return storage }
  
  @inlinable
  public func hash(into hasher: inout Hasher) { normalized.hash(into: &hasher) }
  
  @inlinable
  public static func ==(lhs: IRCServerName, rhs: IRCServerName) -> Bool {
    return lhs.normalized == rhs.normalized
  }
  
  @inlinable
  public static func validate(string: String) -> Bool {
    guard string.count > 1 && string.count <= 63 else {
      return false
    }
    
    // TODO: RFC 2812 2.3.1
    
    return true
  }  
}
