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

import struct NIO.ByteBuffer

fileprivate extension BinaryInteger {
  
  var numberOfDecimalDigits : Int {
    @inline(__always) get {
      var value = self
      var count = 0
      
      repeat {
        value /= 10
        count += 1
      }
      while value != 0
      
      return count
    }
  }
}

extension ByteBuffer {
  
  @discardableResult
  public mutating func write<T: SignedInteger>(integerAsString integer: T,
                                               as: T.Type = T.self) -> Int
  {
    let bytesWritten = set(integerAsString: integer, at: self.writerIndex)
    moveWriterIndex(forwardBy: bytesWritten)
    return Int(bytesWritten)
  }

  @discardableResult
  public mutating func set<T: SignedInteger>(integerAsString integer: T,
                                             at index: Int,
                                             as: T.Type = T.self) -> Int
  {
    let charCount = integer.numberOfDecimalDigits + (integer < 0 ? 1 : 0)
    let avail     = capacity - index
    
    if avail < charCount {
      reserveCapacity(capacity + (charCount - avail))
    }

    self.withVeryUnsafeBytes { rbpp in
      let mrbpp  = UnsafeMutableRawBufferPointer(mutating: rbpp)
      let base   = mrbpp.baseAddress!.assumingMemoryBound(to: UInt8.self)
                        .advanced(by: index)
      var cursor = base.advanced(by: charCount)
      
      let c0 : T = 48
      var negativeAbsoluteValue = integer < 0 ? integer : -integer
      repeat {
        cursor -= 1
        cursor.pointee = UInt8(c0 - (negativeAbsoluteValue % 10))
        negativeAbsoluteValue /= 10;
      }
      while negativeAbsoluteValue != 0
      
      if integer < 0 {
        cursor -= 1
        cursor.pointee = 45 // -
      }

    }
    
    return charCount
  }
}
