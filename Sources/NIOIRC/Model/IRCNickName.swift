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
 * An IRC nickname
 *
 * Channel names are case-insensitive!
 *
 * Maximum length is 9 characters, but clients should support longer for
 * future compat.
 */
public struct IRCNickName : Hashable, CustomStringConvertible {
  
  public typealias StringLiteralType = String
  
  let storage    : String
  let normalized : String
  
  public init?(_ s: String) {
    guard IRCNickName.validate(string: s) else { return nil }
    storage    = s
    normalized = s.ircLowercased()
  }
  
  public var stringValue : String {
    return storage
  }
  
  #if compiler(>=5)
    public func hash(into hasher: inout Hasher) {
      normalized.hash(into: &hasher)
    }
  #else
    public var hashValue: Int {
      return normalized.hashValue
    }
  #endif
  
  public static func ==(lhs: IRCNickName, rhs: IRCNickName) -> Bool {
    return lhs.normalized == rhs.normalized
  }

  public var description : String { return stringValue }

  public static func validate(string: String, strict : Bool = false) -> Bool {
    guard string.count > 1 && string.count <= (strict ? 9 : 1024) else {
      return false
    }
    
    let firstCS = CharacterSets.letterOrSpecial
    let innerCS = CharacterSets.letterDigitSpecialOrDash
    
    let scalars = string.unicodeScalars
    guard firstCS.contains(scalars[scalars.startIndex]) else { return false }
    
    for scalar in scalars.dropFirst() {
      guard innerCS.contains(scalar) else { return false }
    }
    return true
  }

}

import struct Foundation.CharacterSet

fileprivate enum CharacterSets {
  static let letter          = CharacterSet.letters
  static let digit           = CharacterSet.decimalDigits
  static let special         = CharacterSet(charactersIn: "[]\\`_^{|}")
  static let letterOrSpecial = letter.union(special)
  static let letterDigitSpecialOrDash = letter.union(digit).union(special)
                                      .union(CharacterSet(charactersIn: "-"))
}
