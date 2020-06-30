//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-nio-irc open source project
//
// Copyright (c) 2018-2020 ZeeZide GmbH. and the swift-nio-irc project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIOIRC project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct NIO.ByteBuffer
import struct NIO.ByteBufferAllocator
import struct Foundation.Data

// Compat, remove me.
public typealias IRCParserError = IRCMessageParser.Error

/**
 * Parses `IRCMessage` objects from ByteBuffers.
 *
 * The parser is tolerant, if a line fails to parse, it yields an error and
 * continues parsing.
 */
public struct IRCMessageParser {
  // Note: IRC does not actually specify an encoding. Lets be ignorant and
  //       consider it UTF8 ;-)
  
  public enum Error : Swift.Error {
    case invalidPrefix       (Data)
    case invalidCommand      (Data)
    case tooManyArguments    (Data)
    case invalidArgument     (Data)
    
    case invalidArgumentCount(command: String, count: Int, expected: Int)
    case invalidMask         (command: String, mask: String)
    case invalidChannelName  (String)
    case invalidNickName     (String)
    case invalidMessageTarget(String)
    case invalidCAPCommand   (String)
    
    case transportError(Swift.Error)
    case syntaxError
    case notImplemented
  }
  
  public typealias Yield = ( ( Error?, IRCMessage? ) ) -> Void
  
  private let allocator      = ByteBufferAllocator()
  private var overflowBuffer : ByteBuffer? = nil
  
  public mutating func feed(_ buffer: ByteBuffer, yield: Yield) {
    if var ob = overflowBuffer {
      overflowBuffer = nil
      var bb = buffer
      ob.writeBuffer(&bb)
      return feed(ob, yield: yield)
    }
    
    assert(overflowBuffer == nil, "OB should not be set! \(overflowBuffer!)")
    buffer.withUnsafeReadableBytes { bp in
      let cNewline        : UInt8 = 10
      let cCarriageReturn : UInt8 = 13
      var cursor          = bp[bp.startIndex..<bp.endIndex]
      
      while !cursor.isEmpty {
        guard var idx = cursor.firstIndex(of: cNewline) else { break }
        
        let nextCursor = cursor[idx.advanced(by: 1)..<cursor.endIndex]
        if idx > cursor.startIndex && cursor[idx - 1] == cCarriageReturn {
          idx -= 1
        }
        guard cursor.startIndex < idx else {  // skip empty lines
          cursor = nextCursor
          continue
        }
        
        do {
          let message = try processLine(cursor[cursor.startIndex..<idx])
          yield( ( nil, message ) )
        }
        catch {
          yield( ( error as? IRCParserError ?? .syntaxError, nil ) )
        }
        
        cursor = nextCursor
      }
      
      if !cursor.isEmpty {
        overflowBuffer = allocator.buffer(capacity: cursor.count)
        overflowBuffer!.writeBytes(cursor)
      }
    }
  }
  
  typealias Slice = Swift.Slice<UnsafeRawBufferPointer>
  
  @inline(__always)
  private func processLine(_ line: Slice) throws -> IRCMessage {
    // Basic syntax:
    //   [':' SOURCE]? ' ' COMMAND [' ' ARGS]? [' :' LAST-ARG]?
    let cSpace : UInt8 = 32
    let cColon : UInt8 = 58
    let c0     : UInt8 = 48 + 0
    let c9     : UInt8 = 48 + 9
    guard !line.isEmpty else { throw Error.syntaxError }
    
    var cursor = line
    
    func isDigit(_ c: UInt8) -> Bool { return c >= c0 && c <= c9 }
    func isLetter(_ c: UInt8) -> Bool {
      return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A)
    }
    func skipSpaces() {
      while !cursor.isEmpty && cursor[cursor.startIndex] == cSpace {
        cursor = cursor[cursor.startIndex.advanced(by: 1)..<cursor.endIndex]
      }
    }
    func isNoSpaceControlLineFeedColon(_ c: UInt8) -> Bool {
      switch c {
        case 0x01...0x09, 0x0B...0x0C, 0x0E...0x1F, 0x21...0x39, 0x3B...0xFF:
          return true
        default:
          return false
      }
    }

    func makeString(from slice: Slice?) -> String? {
      guard let slice = slice else { return nil }
      return String(data: Data(slice), encoding: .utf8) // Sigh, the pain.
    }

    /* parse source */
    
    let source : Slice?
    
    if cursor[cursor.startIndex] == cColon {
      let startIndex = cursor.startIndex.advanced(by: 1)
      let spaceIdx   = line.firstIndex(of: cSpace)

      guard let endSourceIdx = spaceIdx, endSourceIdx > startIndex else {
        throw Error.invalidPrefix(Data(line))
      }
      
      source = cursor[startIndex..<endSourceIdx]
      assert(!cursor.isEmpty)
      
      cursor = cursor[endSourceIdx..<cursor.endIndex]
      skipSpaces()
    }
    else {
      source = nil
    }
    
    /* parse command name */
    
    guard !cursor.isEmpty else { throw Error.invalidCommand(Data(line)) }
    guard isLetter(cursor[cursor.startIndex])
       || isDigit(cursor[cursor.startIndex]) else {
      throw Error.invalidCommand(Data(line))
    }
    
    enum IRCCommandKey {
      case int   (Int)
      case string(String)
    }
    let commandKey : IRCCommandKey
    
    if isDigit(cursor[cursor.startIndex]) {
      let idx0 = cursor.startIndex
      let idx1 = idx0.advanced(by: 1)
      let idx2 = idx1.advanced(by: 1)
      guard cursor.count >= 3,
            isDigit(cursor[idx1]), isDigit(cursor[idx2]) else {
        throw Error.invalidCommand(Data(line))
      }
      let i0 = cursor[idx0] - c0, i1 = cursor[idx1] - c0, i2 = cursor[idx2] - c0
      commandKey = .int(Int(i0) * 100 + Int(i1) * 10 + Int(i2))
      cursor = cursor[idx2.advanced(by: 1)..<cursor.endIndex]
    }
    else {
      let endIdx = cursor.firstIndex(where: { !isLetter($0) })
                ?? cursor.endIndex
      
      let cmdSlice = cursor[cursor.startIndex..<endIdx]
      guard let s = makeString(from: cmdSlice) else {
        throw Error.invalidCommand(Data(line))
      }
      
      commandKey = .string(s)
      cursor = cursor[endIdx..<cursor.endIndex]
    }
    
    /* parse arguments */
    
    var args = [ String ]()
    
    repeat {
      skipSpaces()
      guard !cursor.isEmpty else { break }
      
      guard args.count < 15 else {
        throw Error.tooManyArguments(Data(line))
      }

      var nextCursor : Slice
      let argSlice   : Slice
      if cursor[cursor.startIndex] == cColon {
        argSlice   = cursor[cursor.startIndex.advanced(by: 1)..<cursor.endIndex]
        nextCursor = cursor[cursor.endIndex..<cursor.endIndex]
      }
      else if isNoSpaceControlLineFeedColon(cursor[cursor.startIndex]) {
        let idxO = cursor.firstIndex(where: {
          !isNoSpaceControlLineFeedColon($0)
        })
        let idx = idxO ?? cursor.endIndex
        argSlice   = cursor[cursor.startIndex..<idx]
        nextCursor = cursor[idx..<cursor.endIndex]
      }
      else {
        throw Error.syntaxError
      }
      
      guard let s = makeString(from: argSlice) else {
        throw Error.invalidArgument(Data(line))
      }
      
      args.append(s)
      
      cursor = nextCursor
    }
    while !cursor.isEmpty
    
    
    /* construct */

    let origin: String?
    if let source = source {
      guard let sourceString = makeString(from: source) else {
        throw Error.invalidPrefix(Data(line))
      }
      origin = sourceString
    }
    else {
      origin = nil
    }
    
    switch commandKey {
      case .string(let s):
        return IRCMessage(origin: origin,
                          command: try IRCCommand(s, arguments: args))
      case .int(let i):
        return IRCMessage(origin: origin,
                          command: try IRCCommand(i, arguments: args))
    }
  }
}
