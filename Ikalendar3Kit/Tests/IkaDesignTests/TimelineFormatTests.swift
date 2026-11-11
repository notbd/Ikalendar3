//
//  TimelineFormatTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaDesign

// MARK: - TimelineFormatTests

/// Pins how Timeline writes times: on the device's hour cycle, two-digit on a 24-hour clock and
/// short on a 12-hour one, a countdown on whole seconds, a day mark where the axis crosses
/// midnight, and Shift ranges, all in the player's time zone.
struct TimelineFormatTests {
  private let tokyo: TimeZone = .init(identifier: "Asia/Tokyo")!
  private let newYork: TimeZone = .init(identifier: "America/New_York")!

  // MARK: Pins

  @Test(arguments: [GameLanguage.enUS, .jaJP, .deDE, .zhCN])
  func `A pin on a 24-hour clock is a two-digit time in the player's time zone`(language: GameLanguage) {
    let format: TimelineFormat = .init(language: language, timeZone: tokyo, hourCycle: .zeroToTwentyThree)

    #expect(String(format.pin(date("2026-10-20T23:00:00Z")).characters) == "08:00")
    #expect(String(format.pin(date("2026-10-20T06:00:00Z")).characters) == "15:00")
  }

  @Test
  func `A pin on a 12-hour clock writes the hour and AM or PM, with minutes only off the hour`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: tokyo, hourCycle: .oneToTwelve)

    #expect(String(format.pin(date("2026-10-20T13:00:00Z")).characters) == "10\u{202F}PM")
    #expect(String(format.pin(date("2026-10-20T13:30:00Z")).characters) == "10:30\u{202F}PM")
  }

  @Test
  func `A pin marks its AM or PM, which the pin sets smaller`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: tokyo, hourCycle: .oneToTwelve)

    let pin = format.pin(date("2026-10-20T13:00:00Z"))
    let marked = pin.runs.filter { $0.foundation.dateField == .amPM }.map { String(pin[$0.range].characters) }

    #expect(marked == ["PM"])
  }

  // MARK: Return time

  @Test
  func `A return time on the same day writes its time alone, else its weekday too`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: tokyo, hourCycle: .oneToTwelve)
    let now = date("2026-08-23T03:00:00Z")

    #expect(format.time(date("2026-08-23T11:00:00Z"), relativeTo: now) == "8\u{202F}PM")
    #expect(format.time(date("2026-08-24T11:00:00Z"), relativeTo: now) == "Mon 8\u{202F}PM")
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
    #expect(TimelineFormat.countdown(.milliseconds(59200)) == "0:01:00")
  }

  @Test
  func `A Shift's countdown runs its hours past a day`() {
    #expect(TimelineFormat.countdown(.seconds(48 * 3600 - 1)) == "47:59:59")
  }

  // MARK: Days

  @Test
  func `The axis marks a day where a start falls on a new day in the player's time zone`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: newYork, hourCycle: .zeroToTwentyThree)

    // 22:00 and 00:00 in New York.
    #expect(format.startsNewDay(date("2026-10-21T04:00:00Z"), after: date("2026-10-21T02:00:00Z")))
    // 20:00 and 22:00 in New York, though the second is the next day in UTC.
    #expect(!format.startsNewDay(date("2026-10-21T02:00:00Z"), after: date("2026-10-21T00:00:00Z")))
  }

  @Test
  func `The first start on the axis always marks its day`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: newYork, hourCycle: .zeroToTwentyThree)

    #expect(format.startsNewDay(date("2026-10-21T02:00:00Z"), after: nil))
  }

  // MARK: Ranges

  @Test
  func `A Shift's range writes each end's weekday and 24-hour time`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: tokyo, hourCycle: .zeroToTwentyThree)

    let range = format.timeRange(from: date("2026-10-20T08:00:00Z"), to: date("2026-10-22T00:00:00Z"))

    #expect(range == "Tue 17:00 - Thu 09:00")
  }

  @Test
  func `A Shift's range on a 12-hour clock writes each end's weekday, hour and AM or PM`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: tokyo, hourCycle: .oneToTwelve)

    let range = format.timeRange(from: date("2026-10-20T08:00:00Z"), to: date("2026-10-22T00:00:00Z"))

    #expect(range == "Tue 5\u{202F}PM - Thu 9\u{202F}AM")
  }

  @Test
  func `A range in Japanese joins its ends with a wave dash, as the game does`() {
    let format: TimelineFormat = .init(language: .jaJP, timeZone: tokyo, hourCycle: .zeroToTwentyThree)

    let range = format.timeRange(from: date("2026-10-20T08:00:00Z"), to: date("2026-10-22T00:00:00Z"))

    #expect(range == "火 17:00 ~ 木 09:00")
  }

  /// A Challenge window on the axis sits under its day mark, so its range carries no weekday.
  @Test
  func `A range under a day mark writes only each end's 24-hour time`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: tokyo, hourCycle: .zeroToTwentyThree)

    let range = format.hourRange(from: date("2026-10-20T08:00:00Z"), to: date("2026-10-20T10:00:00Z"))

    #expect(range == "17:00 - 19:00")
  }

  /// A Splatfest is announced weeks ahead, so its range carries each end's date.
  @Test
  func `A Splatfest's range writes each end's weekday, date and 24-hour time`() {
    let format: TimelineFormat = .init(language: .enUS, timeZone: tokyo, hourCycle: .zeroToTwentyThree)

    let range = format.dateRange(from: date("2026-10-31T00:00:00Z"), to: date("2026-11-02T00:00:00Z"))

    #expect(range == "Sat, 10/31, 09:00 - Mon, 11/2, 09:00")
  }
}
