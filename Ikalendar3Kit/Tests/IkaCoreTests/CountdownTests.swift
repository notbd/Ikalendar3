//
//  CountdownTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

struct CountdownTests {
  /// A time left in milliseconds and the hours, minutes and seconds every countdown shows for it.
  struct CountdownCase: CustomTestStringConvertible {
    let milliseconds: Int64
    let parts: [Int]

    var testDescription: String { "\(milliseconds) ms" }
  }

  @Test(arguments: [
    CountdownCase(milliseconds: 4_805_000, parts: [1, 20, 5]),
    CountdownCase(milliseconds: 3_607_000, parts: [1, 0, 7]),
    CountdownCase(milliseconds: 59200, parts: [0, 1, 0]),
    CountdownCase(milliseconds: 400, parts: [0, 0, 1]),
    CountdownCase(milliseconds: (48 * 3600 - 1) * 1000, parts: [47, 59, 59]),
    CountdownCase(milliseconds: 0, parts: [0, 0, 0]),
    CountdownCase(milliseconds: -4000, parts: [0, 0, 0]),
  ])
  func `A countdown splits the time left, rounded up to the second, into hours past a day, minutes and seconds`(
    _ countdown: CountdownCase)
  {
    let parts: Countdown = .init(.milliseconds(countdown.milliseconds))

    #expect([parts.hours, parts.minutes, parts.seconds] == countdown.parts)
  }
}
