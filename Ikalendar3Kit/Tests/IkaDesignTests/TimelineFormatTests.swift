//
//  TimelineFormatTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import Testing
@testable import IkaDesign

// MARK: - TimelineFormatTests

/// Pins how Timeline writes times: SplatNet 3's two-digit 24-hour pins whatever the device's hour
/// cycle, a countdown on whole seconds, a day mark where the axis crosses midnight, and Shift
/// ranges, all in the player's time zone.
struct TimelineFormatTests {
  private let tokyo: TimeZone = .init(identifier: "Asia/Tokyo")!
  private let newYork: TimeZone = .init(identifier: "America/New_York")!

  // MARK: Pins

  @Test(arguments: [GameLanguage.enUS, .jaJP, .deDE, .zhCN])
  func `A pin is a two-digit 24-hour time in the player's time zone`(language: GameLanguage) {
    let format: TimelineFormat = .init(language: language, timeZone: tokyo)

    #expect(format.pin(date("2026-10-20T23:00:00Z")) == "08:00")
    #expect(format.pin(date("2026-10-20T06:00:00Z")) == "15:00")
  }

  // MARK: Countdown

  @Test
  func `A countdown writes hours, minutes and seconds`() {
    #expect(TimelineFormat.countdown(.seconds(4199)) == "1:09:59")
    #expect(TimelineFormat.countdown(.seconds(59)) == "0:00:59")
  }

  @Test
  func `A countdown rounds up to the second, so a running window never reads zero`() {
    #expect(TimelineFormat.countdown(.milliseconds(200)) == "0:00:01")
    #expect(TimelineFormat.countdown(.milliseconds(59_200)) == "0:01:00")
  }

  @Test
  func `A Shift's countdown runs its hours past a day`() {
    #expect(TimelineFormat.countdown(.seconds(48 * 3600 - 1)) == "47:59:59")
  }

  // MARK: Days

  @Test
  func `The axis marks a day where a start falls on a new day in the player's time zone`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: newYork)

    // 22:00 and 00:00 in New York.
    #expect(format.startsNewDay(date("2026-10-21T04:00:00Z"), after: date("2026-10-21T02:00:00Z")))
    // 20:00 and 22:00 in New York, though the second is the next day in UTC.
    #expect(!format.startsNewDay(date("2026-10-21T02:00:00Z"), after: date("2026-10-21T00:00:00Z")))
  }

  @Test
  func `The first start on the axis always marks its day`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: newYork)

    #expect(format.startsNewDay(date("2026-10-21T02:00:00Z"), after: nil))
  }

  // MARK: Ranges

  @Test
  func `A Shift's range writes each end's weekday and 24-hour time`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: tokyo)

    let range = format.timeRange(from: date("2026-10-20T08:00:00Z"), to: date("2026-10-22T00:00:00Z"))

    #expect(range == "Tue 17:00 - Thu 09:00")
  }

  @Test
  func `A range in Japanese joins its ends with a wave dash, as the game does`() {
    let format: TimelineFormat = .init(language: .jaJP, timeZone: tokyo)

    let range = format.timeRange(from: date("2026-10-20T08:00:00Z"), to: date("2026-10-22T00:00:00Z"))

    #expect(range == "火 17:00 ~ 木 09:00")
  }

  // MARK: Helpers

  private func date(_ text: String) -> Date {
    // A test literal: a malformed one should stop the test at once.
    // swiftlint:disable:next force_try
    try! Date(text, strategy: .iso8601)
  }
}
