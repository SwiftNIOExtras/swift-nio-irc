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
 * An IRC nickname
 *
 * Channel names are case-insensitive!
 *
 * Maximum length is 9 characters, but clients should support longer for
 * future compat.
 */
public struct IRCNickName : Hashable, CustomStringConvertible {
  
  public typealias StringLiteralType = String
  
  @usableFromInline let storage    : String
  @usableFromInline let normalized : String
  
  public struct ValidationFlags: OptionSet {
    public let rawValue : UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    
    /**
     * A violation of the IRC spec, but Twitch IRC chatrooms seem to allow
     * usernames that start w/ a digit.
     * As per issue #6, thanks @gbeaman.
     */
    public static let allowStartingDigit = ValidationFlags(rawValue: 1 << 0)
    
    /**
     * Per RFC a nickname has to be between 2...9 characters, but that is
     * rarely the case in practice.
     * By default we allow up to 1024 characters.
     */
    public static let strictLengthLimit  = ValidationFlags(rawValue: 1 << 1)
  }
  
  @inlinable
  public init?(_ s: String,
               validationFlags: ValidationFlags = [ .allowStartingDigit ])
  {
    guard IRCNickName.validate(string: s,
                               validationFlags: validationFlags) else
    {
      return nil
    }
    storage    = s
    normalized = s.ircLowercased()
  }
  
  @inlinable
  public var stringValue : String {
    return storage
  }
  
  @inlinable
  public func hash(into hasher: inout Hasher) {
    normalized.hash(into: &hasher)
  }
  
  @inlinable
  public static func ==(lhs: IRCNickName, rhs: IRCNickName) -> Bool {
    return lhs.normalized == rhs.normalized
  }

  @inlinable
  public var description : String { return stringValue }

  public static func validate(string: String, validationFlags: ValidationFlags)
                     -> Bool
  {
    let strict = validationFlags.contains(.strictLengthLimit)
    guard string.count > 1 && string.count <= (strict ? 9 : 1024) else {
      return false
    }
    
    let firstCS = validationFlags.contains(.allowStartingDigit)
      ? CharacterSets.letterDigitOrSpecial
      : CharacterSets.letterOrSpecial
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
  static let letter                   = CharacterSet.letters
  static let digit                    = CharacterSet.decimalDigits
  static let special                  = CharacterSet(charactersIn: "[]\\`_^{|}")
  static let letterOrSpecial          = letter.union(special)
  static let letterDigitOrSpecial     = letter.union(digit).union(special)
  static let letterDigitSpecialOrDash = letterDigitOrSpecial
                                        .union(CharacterSet(charactersIn: "-"))
}
