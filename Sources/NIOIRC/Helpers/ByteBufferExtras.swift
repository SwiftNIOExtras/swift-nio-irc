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

import struct NIO.ByteBuffer

public extension ByteBuffer {
  // This looks expensive, but isn't. As per @weissi String's store up to 15
  // bytes inline, no alloc necessary.
  
  /**
   * Write an Integer as an ASCII String.
   */
  @inlinable
  @discardableResult
  mutating func write<T: SignedInteger>(integerAsString integer: T,
                                        as: T.Type = T.self) -> Int
  {
    return self.writeString(String(integer, radix: 10))
  }

  /**
   * Set an Integer as an ASCII String.
   */
  @inlinable
  @discardableResult
  mutating func set<T: SignedInteger>(integerAsString integer: T,
                                      at index: Int,
                                      as: T.Type = T.self) -> Int
  {
    return self.setString(String(integer, radix: 10), at: index)
  }
}
