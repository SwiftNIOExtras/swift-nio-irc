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

extension String {
  // You wonder why, admit it! ;-)
  
  @usableFromInline
  func ircLowercased() -> String {
    return String(lowercased().map { c in
      switch c {
        case "[":  return "{"
        case "]":  return "}"
        case "\\": return "|"
        case "~":  return "^"
        default:   return c
      }
    })
  }
}
