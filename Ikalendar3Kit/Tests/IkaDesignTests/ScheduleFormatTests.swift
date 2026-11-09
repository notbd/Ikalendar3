//
//  ScheduleFormatTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore
@testable import IkaDesign

struct ScheduleFormatTests {
  /// Council round 5, M8: the hour cycle comes from the view's `TimeSettings`, which previews and
  /// tests can set, not from the process.
  @Test
  func `Times are written on the hour cycle passed in`() throws {
    let utc = try #require(TimeZone(identifier: "UTC"))
    let rotation: Rotation = .init(
      mode: .battle(.x),
      startTime: date("2026-10-20T16:00:00Z"),
      endTime: date("2026-10-20T18:00:00Z"),
      setting: nil)

    let twentyFour: ScheduleFormat = .init(language: .enUS, timeZone: utc, hourCycle: .zeroToTwentyThree)
    let twelve: ScheduleFormat = .init(language: .enUS, timeZone: utc, hourCycle: .oneToTwelve)

    #expect(twentyFour.timeRange(of: rotation) == "16:00\u{2009}–\u{2009}18:00")
    #expect(twelve.timeRange(of: rotation) == "4:00\u{2009}–\u{2009}6:00\u{202F}PM")
  }
}
