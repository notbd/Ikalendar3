//
//  InkTimeFormatTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaDesign

/// Pins the one way Ink's screens write a window: times alone within today, the weekday where a
/// day is not today, the date only from a week away, and never a numeric date with its year.
struct InkTimeFormatTests {
  private struct Window: TimeWindow {
    let startTime: Date
    let endTime: Date

    init(_ start: String, _ end: String) {
      startTime = date(start)
      endTime = date(end)
    }
  }

  private func format(
    _ language: GameLanguage = .enUS,
    timeZone: TimeZone = .gmt,
    hourCycle: Locale.HourCycle = .zeroToTwentyThree)
    -> InkTimeFormat
  {
    .init(language: language, timeZone: timeZone, hourCycle: hourCycle)
  }

  // MARK: Windows within a day

  @Test
  func `A Rotation within today shows its times alone`() {
    let rotation: Window = .init("2026-10-20T14:00:00Z", "2026-10-20T16:00:00Z")

    #expect(format().range(of: rotation, now: date("2026-10-20T15:00:00Z")) == "14:00 - 16:00")
  }

  @Test
  func `A Rotation that crosses midnight still shows its times alone, on a 12-hour clock too`() {
    let rotation: Window = .init("2026-10-20T22:00:00Z", "2026-10-21T00:00:00Z")
    let now = date("2026-10-20T23:10:00Z")
    // The system separates the day period with a narrow no-break space.
    let twelve: String = format(hourCycle: .oneToTwelve)
      .range(of: rotation, now: now)
      .replacing("\u{202F}", with: " ")

    #expect(format().range(of: rotation, now: now) == "22:00 - 00:00")
    #expect(twelve == "10:00 PM - 12:00 AM")
  }

  @Test
  func `A Rotation on another day carries its weekday on the start only`() {
    let rotation: Window = .init("2026-10-21T00:00:00Z", "2026-10-21T02:00:00Z")

    #expect(format().range(of: rotation, now: date("2026-10-20T23:10:00Z")) == "Wed 00:00 - 02:00")
  }

  @Test
  func `A window a week or more away carries its date too`() {
    let window: Window = .init("2026-10-27T14:00:00Z", "2026-10-27T16:00:00Z")

    #expect(format().range(of: window, now: date("2026-10-20T15:00:00Z")) == "Tue, 10/27, 14:00 - 16:00")
  }

  // MARK: Time zones

  @Test
  func `Today is the player's day, not the day in UTC`() throws {
    // 23:00 on Tuesday to 01:00 on Wednesday in Tokyo, read ten minutes into Wednesday there: one
    // day in UTC, two days for the player.
    let tokyo: TimeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
    let rotation: Window = .init("2026-10-20T14:00:00Z", "2026-10-20T16:00:00Z")
    let now = date("2026-10-20T15:10:00Z")

    #expect(format(timeZone: tokyo).range(of: rotation, now: now) == "Tue 23:00 - 01:00")
    #expect(format().range(of: rotation, now: now) == "14:00 - 16:00")
  }

  @Test
  func `A Rotation over the end of daylight saving time shows the clock's times`() throws {
    // Toronto's clocks go back from 02:00 to 01:00 at 06:00 UTC on 1 November 2026.
    let toronto: TimeZone = try #require(TimeZone(identifier: "America/Toronto"))
    let before: Window = .init("2026-11-01T04:00:00Z", "2026-11-01T06:00:00Z")
    let after: Window = .init("2026-11-01T06:00:00Z", "2026-11-01T08:00:00Z")
    let now = date("2026-11-01T05:00:00Z")

    #expect(format(timeZone: toronto).range(of: before, now: now) == "00:00 - 01:00")
    #expect(format(timeZone: toronto).range(of: after, now: now) == "01:00 - 03:00")
  }

  // MARK: Windows over days

  @Test
  func `A Shift names the day of both ends, today's included`() {
    let shift: Window = .init("2026-10-20T16:00:00Z", "2026-10-22T08:00:00Z")

    #expect(format().range(of: shift, now: date("2026-10-20T18:00:00Z")) == "Tue 16:00 - Thu 08:00")
  }

  @Test
  func `A Splatfest announced weeks ahead carries its dates`() {
    let splatfest: Window = .init("2026-10-31T00:00:00Z", "2026-11-02T00:00:00Z")

    #expect(
      format().range(of: splatfest, now: date("2026-10-20T12:00:00Z")) == "Sat, 10/31, 00:00 - Mon, 11/2, 00:00")
  }

  // MARK: Instants

  @Test
  func `An instant shows its time today and its day otherwise`() {
    let now = date("2026-10-20T12:00:00Z")

    #expect(format().time(date("2026-10-20T20:00:00Z"), now: now) == "20:00")
    #expect(format().time(date("2026-10-21T20:00:00Z"), now: now) == "Wed 20:00")
  }

  // MARK: Languages

  @Test
  func `A range joins its ends as every Style does, with a wave dash in Japanese`() {
    let rotation: Window = .init("2026-10-20T14:00:00Z", "2026-10-20T16:00:00Z")

    #expect(format(.jaJP).range(of: rotation, now: date("2026-10-20T15:00:00Z")) == "14:00 ~ 16:00")
  }

  @Test(arguments: GameLanguage.allCases)
  func `No language writes a year`(language: GameLanguage) {
    let rotation: Window = .init("2026-10-20T22:00:00Z", "2026-10-21T00:00:00Z")
    let splatfest: Window = .init("2026-10-31T00:00:00Z", "2026-11-02T00:00:00Z")
    let now = date("2026-10-20T23:10:00Z")

    for hourCycle: Locale.HourCycle in [.oneToTwelve, .zeroToTwentyThree] {
      let format: InkTimeFormat = format(language, hourCycle: hourCycle)

      #expect(!format.range(of: rotation, now: now).contains("2026"))
      #expect(!format.range(of: splatfest, now: now).contains("2026"))
    }
  }
}
