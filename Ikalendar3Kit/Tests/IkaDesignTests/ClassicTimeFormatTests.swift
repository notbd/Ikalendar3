//
//  ClassicTimeFormatTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaDesign

/// Pins how Classic writes times as ikalendar 2 did: a Rotation's range with the day only where
/// it leaves today, a Shift's ends with their day, and countdowns down to the second, in the
/// player's time zone.
struct ClassicTimeFormatTests {
  private let tokyo: TimeZone = .init(identifier: "Asia/Tokyo")!

  private func format(
    _ language: GameLanguage = .enUS,
    timeZone: TimeZone = .gmt,
    hourCycle: Locale.HourCycle = .zeroToTwentyThree)
    -> ClassicTimeFormat
  {
    .init(language: language, timeZone: timeZone, hourCycle: hourCycle)
  }

  // MARK: Rotations

  @Test
  func `A Rotation within today shows its times alone`() {
    let range = format().battleRange(
      from: date("2026-10-20T14:00:00Z"),
      to: date("2026-10-20T16:00:00Z"),
      now: date("2026-10-20T13:00:00Z"))

    #expect(range == "14:00 - 16:00")
  }

  @Test
  func `A Rotation that ends tomorrow marks its end`() {
    let range = format().battleRange(
      from: date("2026-10-20T22:00:00Z"),
      to: date("2026-10-21T00:00:00Z"),
      now: date("2026-10-20T13:00:00Z"))

    #expect(range == "22:00 - Tomorrow 00:00")
  }

  @Test
  func `A Rotation that starts tomorrow marks its start`() {
    let range = format().battleRange(
      from: date("2026-10-21T02:00:00Z"),
      to: date("2026-10-21T04:00:00Z"),
      now: date("2026-10-20T23:00:00Z"))

    #expect(range == "Tomorrow 02:00 - 04:00")
  }

  @Test
  func `A Rotation that started yesterday marks both ends`() {
    let range = format().battleRange(
      from: date("2026-10-19T23:00:00Z"),
      to: date("2026-10-20T01:00:00Z"),
      now: date("2026-10-20T00:30:00Z"))

    #expect(range == "Yesterday 23:00 - Today 01:00")
  }

  @Test
  func `Times follow the player's time zone and hour cycle`() {
    let range = format(timeZone: tokyo, hourCycle: .oneToTwelve).battleRange(
      from: date("2026-10-20T14:00:00Z"),
      to: date("2026-10-20T16:00:00Z"),
      now: date("2026-10-20T13:00:00Z"))

    // 23:00 to 01:00 in Tokyo.
    #expect(range == "11:00\u{202F}PM - Tomorrow 1:00\u{202F}AM")
  }

  // MARK: Shifts

  @Test
  func `A Shift's ends carry their day, near ones by name`() {
    let start = format().shiftTime(date("2026-10-20T16:00:00Z"), now: date("2026-10-20T13:00:00Z"))
    let end = format().shiftTime(date("2026-10-22T08:00:00Z"), now: date("2026-10-20T13:00:00Z"))

    #expect(start == "Today 16:00")
    #expect(end == "Thu, 10/22, 08:00")
  }

  @Test
  func `Day words are the text set's own`() {
    let time = format(.jaJP).shiftTime(date("2026-10-21T16:00:00Z"), now: date("2026-10-20T13:00:00Z"))

    #expect(time == "あした 16:00")
  }

  // MARK: Countdowns

  @Test
  func `A countdown runs to the second and leaves out empty larger units`() {
    #expect(format().span(.seconds(36 * 3600 + 5 * 60 + 9)) == "1d 12h 5m 9s")
    #expect(format().span(.seconds(5 * 60)) == "5m 0s")
    #expect(format().span(.seconds(3600 + 7)) == "1h 7s")
    #expect(format().span(.zero) == "0s")
  }

  @Test
  func `A countdown joins its units as the text set writes them`() {
    #expect(format(.jaJP).span(.seconds(3600 + 2 * 60 + 3)) == "1時間2分3秒")
    #expect(format(.zhCN).span(.seconds(2 * 60 + 3)) == "2分钟3秒")
    #expect(format(.koKR).span(.seconds(2 * 60 + 3)) == "2분 3초")
  }

  @Test
  func `A countdown never reads below zero`() {
    #expect(format().span(.seconds(-4)) == "0s")
  }

  @Test
  func `A countdown rounds up to the second, as every Style's, so a running window never reads zero`() {
    #expect(format().span(.milliseconds(59200)) == "1m 0s")
    #expect(format().span(.milliseconds(400)) == "1s")
  }

  @Test
  func `Countdowns read as time left and time until`() {
    #expect(ClassicText.timeLeft.text(in: .enUS, "1h 7s") == "1h 7s remaining")
    #expect(ClassicText.timeUntil.text(in: .enUS, "5m 0s") == "in 5m 0s")
    #expect(ClassicText.timeLeft.text(in: .jaJP, "1時間") == "残り1時間")
  }

  // MARK: Catalog

  @Test(arguments: ClassicText.allCases)
  func `Every Classic string has a text in every text set`(text: ClassicText) {
    for language in GameLanguage.allCases {
      #expect(text.text(in: language) != text.rawValue, "\(text.rawValue) in \(language.rawValue)")
    }
  }
}
