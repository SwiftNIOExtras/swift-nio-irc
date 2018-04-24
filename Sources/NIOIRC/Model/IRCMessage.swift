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

/**
 * An IRC message
 *
 * An optional origin, an optional target and the actual command (including its
 * arguments).
 */
public struct IRCMessage : Codable, CustomStringConvertible {

  public enum CodingKeys: String, CodingKey {
    case origin, target, command, arguments
  }

  public init(origin: String? = nil, target: String? = nil,
              command: IRCCommand)
  {
    self._storage = _Storage(origin: origin, target: target, command: command)
  }

  /**
   * True origin of message. Do not set in clients.
   *
   * Examples:
   * - `:helge55!~textual@213.211.198.125`
   * - `:helge99`
   * - `:cherryh.freenode.net`
   *
   * This is a server name or a nickname w/ user@host parts.
   */
  public var origin : String? {
    set { copyStorageIfNeeded(); _storage.origin = newValue }
    get { return _storage.origin }
  }
  
  public var target : String? {
    set { copyStorageIfNeeded(); _storage.target = newValue }
    get { return _storage.target }
  }

  /**
   * The IRC command and its arguments (max 15).
   */
  public var command : IRCCommand {
    set { copyStorageIfNeeded(); _storage.command = newValue }
    get { return _storage.command }
  }
  
  public var description: String {
    var ms = "<IRCMsg:"
    if let origin = origin { ms += " from=\(origin)" }
    if let target = target { ms += " to=\(target)" }
    ms += " "
    ms += command.description
    ms += ">"
    return ms
  }
  
  
  // MARK: - Internal Storage to keep the value small
  
  @inline(__always)
  private mutating func copyStorageIfNeeded() {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _Storage(_storage)
    }
  }

  private class _Storage {
    var origin  : String?
    var target  : String?
    var command : IRCCommand

    init(origin: String?, target: String?, command: IRCCommand) {
      self.origin  = origin
      self.target  = target
      self.command = command
    }
    init(_ other: _Storage) {
      self.origin  = other.origin
      self.target  = other.target
      self.command = other.command
    }
  }
  private var _storage : _Storage
  
  
  // MARK: - Codable

  public init(from decoder: Decoder) throws {
    let c       = try decoder.container(keyedBy: CodingKeys.self)
    let cmd     = try c.decode(String.self,              forKey: .command)
    let args    = try c.decodeIfPresent([ String ].self, forKey: .arguments)
    let command = try IRCCommand(cmd, arguments: args ?? [])
    
    self.init(origin: try c.decodeIfPresent(String.self, forKey: .origin),
              target: try c.decodeIfPresent(String.self, forKey: .target),
              command: command)
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encodeIfPresent(origin,         forKey: .origin)
    try c.encodeIfPresent(target,         forKey: .target)
    try c.encode(command.commandAsString, forKey: .command)
    try c.encode(command.arguments,       forKey: .arguments)
  }
}
