//
//  SentenceWriterTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct SentenceWriterTests {
  /// X Battle's Splat Zones on Scorch Gorge and Eeltail Alley, 16:00 to 18:00 UTC on the epoch's
  /// day (a Thursday).
  static let rotation: Rotation = .init(
    mode: .battle(.x),
    startTime: TestData.instant(hours: 16),
    endTime: TestData.instant(hours: 18),
    setting: .init(rule: RuleID("VnNSdWxlLTE="), stages: [StageID("VnNTdGFnZS0x"), StageID("VnNTdGFnZS0y")]))

  static let losAngeles: TimeZone = .init(identifier: "America/Los_Angeles")!

  /// A writer in en-US, Los Angeles time and the 12-hour cycle.
  static func writer(
    _ language: GameLanguage = .enUS,
    timeZone: TimeZone = losAngeles,
    hourCycle: Locale.HourCycle = .oneToTwelve)
    -> SentenceWriter
  {
    SentenceWriter(
      terms: GameTerms(language: language, refreshed: nil, feed: TermTable()),
      timeZone: timeZone,
      hourCycle: hourCycle)
  }

  @Test
  func `A running Rotation reads its Battle Mode, Rule, Stages, time range and time left`() {
    let sentence = Self.writer().sentence(for: Self.rotation, at: TestData.instant(hours: 16 + 40.0 / 60))

    #expect(sentence == "X Battle: Splat Zones on Scorch Gorge and Eeltail Alley, "
      + "from 8:00\u{202F}AM to 10:00\u{202F}AM, 1 hour 20 minutes left.")
  }

  @Test
  func `A Rotation not running reads no time left`() {
    let sentence = Self.writer().sentence(for: Self.rotation, at: TestData.instant(hours: 15))

    #expect(sentence ==
      "X Battle: Splat Zones on Scorch Gorge and Eeltail Alley, from 8:00\u{202F}AM to 10:00\u{202F}AM.")
  }

  /// The recorded decision (ticket 08): a paused Battle Mode reads when it comes back, as the
  /// iPhone tabs do, never a paused window's own times.
  @Test
  func `A Battle Mode a Splatfest pauses reads when it comes back`() {
    let sentence = Self.writer().sentence(forPauseOf: .anarchySeries, returningAt: TestData.instant(hours: 4 * 24 + 17))

    #expect(sentence == "Anarchy Battle (Series): paused during the Splatfest until Monday 9:00\u{202F}AM.")
  }

  @Test
  func `A summary's pause gives the pause sentence its Battle Mode and return time`() async throws {
    let snapshot: Snapshot = try await .schedules(.splatfestSecondHalf)

    let summary = snapshot.summary(of: .battle(.regular), at: date("2026-11-01T06:00:00Z"))

    guard case .battle(let mode, .paused(let returnTime)) = summary else {
      Issue.record("\(String(describing: summary))")
      return
    }
    #expect(Self.writer().sentence(forPauseOf: mode, returningAt: returnTime) ==
      "Regular Battle: paused during the Splatfest until Sunday 4:00\u{202F}PM.")
  }

  @Test
  func `A Shift reads its Stage, four weapons with random marks, time range and time left`() {
    let shift: Shift = .init(
      kind: .regular,
      startTime: TestData.instant(hours: 16),
      endTime: TestData.instant(hours: 56),
      stage: StageID("Q29vcFN0YWdlLTE="),
      weapons: [WeaponID("e60629ecf35192a1"), .random, WeaponID("961a7063fc94f087"), .rareRandom],
      kingSalmonid: nil)

    let sentence = Self.writer().sentence(for: shift, at: TestData.instant(hours: 54))

    #expect(sentence == "Salmon Run: Spawning Grounds with Splattershot, Random, Splat Charger, and Rare Random, "
      + "from Thursday 8:00\u{202F}AM to Saturday 12:00\u{202F}AM, 2 hours left.")
  }

  // MARK: Tracking

  /// Tracking's items read as the Rotation, pause and Shift they stand for, so the Live
  /// Activity's VoiceOver says what the screens and Siri say.
  @Test
  func `Tracking's items read the same sentences as the items they stand for`() async throws {
    let normalDay = try await ScheduleFeed.decode(from: Fixture.normalDay.data())
    let splatfest = try await ScheduleFeed.decode(from: Fixture.splatfestSecondHalf.data())
    let instant: Date = date("2026-10-20T13:00:00Z")

    guard
      case .battle(_, let rotations) = normalDay.trackingContent(of: .battle(.x), at: instant),
      case .battle(_, let pauses) = splatfest.trackingContent(of: .battle(.regular), at: date("2026-11-01T06:00:00Z")),
      case .salmonRun(let shifts) = normalDay.trackingContent(of: .salmonRun, at: instant)
    else {
      Issue.record("Tracking content of another Mode")
      return
    }
    let writer = Self.writer()

    #expect(try writer.sentence(for: #require(rotations.first), of: .x, at: instant) ==
      "X Battle: Tower Control on Mahi-Mahi Resort and Robo ROM-en, from 5:00\u{202F}AM to 7:00\u{202F}AM, 1 hour left.")
    #expect(try writer.sentence(for: #require(pauses.first), of: .regular, at: instant) ==
      "Regular Battle: paused during the Splatfest until Sunday 4:00\u{202F}PM.")
    #expect(try writer.sentence(for: #require(shifts.first), at: instant) ==
      "Salmon Run: Jammin' Salmon Junction with S-BLAST '92, Splat Dualies, Splash-o-matic, and Goo Tuber, "
      + "from Sunday 5:00\u{202F}PM to Tuesday 9:00\u{202F}AM, 3 hours left.")
  }

  @Test
  func `A tracked Big Run reads as a Big Run`() {
    let bigRun: TrackedShift = .init(
      startTime: TestData.instant(hours: 16),
      endTime: TestData.instant(hours: 64),
      isBigRun: true,
      stage: StageID("Q29vcFN0YWdlLTE="),
      weapons: [.random, .random, .random, .random])

    #expect(Self.writer().sentence(for: bigRun, at: TestData.instant(hours: 0)) ==
      "Big Run: Spawning Grounds with Random, Random, Random, and Random, "
      + "from Thursday 8:00\u{202F}AM to Saturday 8:00\u{202F}AM.")
  }

  // MARK: Languages

  @Test(arguments: GameLanguage.allCases)
  func `Every sentence resolves with every name in each language`(language: GameLanguage) {
    let writer: SentenceWriter = Self.writer(language)
    let terms = writer.terms
    let series: Rotation = .init(
      mode: .battle(.anarchySeries),
      startTime: Self.rotation.startTime,
      endTime: Self.rotation.endTime,
      setting: Self.rotation.setting)
    let bigRun: Shift = .init(
      kind: .bigRun,
      startTime: TestData.instant(hours: 16),
      endTime: TestData.instant(hours: 64),
      stage: StageID("VnNTdGFnZS0x"),
      weapons: [WeaponID("e60629ecf35192a1"), .random, .rareRandom, .rareRandom],
      kingSalmonid: nil)
    let instant: Date = TestData.instant(hours: 16.5)

    let names: [String] = [
      terms.name(of: RuleID("VnNSdWxlLTE=")),
      terms.name(of: StageID("VnNTdGFnZS0x")),
      terms.name(of: StageID("VnNTdGFnZS0y")),
      terms.name(of: WeaponID("e60629ecf35192a1")),
      terms.name(of: WeaponID.random),
      ModeLabel.anarchyBattle.text(in: language),
      ModeLabel.series.text(in: language),
      ModeLabel.bigRun.text(in: language),
    ]
    let texts = [
      writer.sentence(for: series, at: instant),
      writer.sentence(forPauseOf: .anarchyOpen, returningAt: instant),
      writer.sentence(for: bigRun, at: instant),
      writer.timeLeft(WindowProgress(timeLeft: .seconds(4800), sharePassed: 0.5)),
    ] + TrackingReminder.allCases.map { $0.text(in: language) }

    for text in texts {
      #expect(!text.isEmpty && !text.contains("%"), "\(language.rawValue): \(text)")
      for key in ["sentence.", "weapon.", "reminder."] {
        #expect(!text.contains(key), "\(language.rawValue): \(text)")
      }
    }
    for name in names {
      #expect(!name.isEmpty && !name.contains("="), "\(language.rawValue): [\(name)]")
    }
    #expect(texts[0].contains(names[0]) && texts[0].contains(names[1]) && texts[0].contains(names[2]), "\(texts[0])")
    #expect(texts[0].contains(names[5]) && texts[0].contains(names[6]), "\(texts[0])")
    #expect(texts[2].contains(names[3]) && texts[2].contains(names[4]) && texts[2].contains(names[7]), "\(texts[2])")
    if ![.enUS, .enGB].contains(language) {
      #expect(texts[0] != Self.writer(.enUS).sentence(for: series, at: instant))
    }
  }

  // MARK: Time left

  /// A time left in seconds and how it reads in a text set.
  struct TimeLeftCase: CustomTestStringConvertible {
    let seconds: Int64
    let language: GameLanguage
    let text: String

    var testDescription: String { "\(seconds) s in \(language.rawValue)" }
  }

  @Test(arguments: [
    TimeLeftCase(seconds: 7200, language: .enUS, text: "2 hours left"),
    TimeLeftCase(seconds: 3660, language: .enUS, text: "1 hour 1 minute left"),
    TimeLeftCase(seconds: 59 * 60 + 1, language: .enUS, text: "1 hour left"),
    TimeLeftCase(seconds: 1, language: .enUS, text: "1 minute left"),
    TimeLeftCase(seconds: 39 * 3600 + 5 * 60, language: .enUS, text: "39 hours 5 minutes left"),
    TimeLeftCase(seconds: 4800, language: .jaJP, text: "残り1時間20分"),
    TimeLeftCase(seconds: 4800, language: .zhCN, text: "剩余1小时20分钟"),
    TimeLeftCase(seconds: 2 * 3600 + 22 * 60, language: .ruRU, text: "осталось: 2 часа 22 минуты"),
  ])
  func `Progress reads as the time left in hours and minutes, rounded up`(_ timeLeft: TimeLeftCase) {
    let progress: WindowProgress = .init(timeLeft: .seconds(timeLeft.seconds), sharePassed: 0.5)

    #expect(Self.writer(timeLeft.language).timeLeft(progress) == timeLeft.text)
  }

  // MARK: Time ranges

  /// A text set, time zone and hour cycle, and how the epoch's 16:00 to 18:00 UTC Rotation reads.
  struct TimeRangeCase: CustomTestStringConvertible {
    let language: GameLanguage
    let timeZone: String
    let hourCycle: Locale.HourCycle
    let range: String

    var testDescription: String { "\(language.rawValue), \(timeZone), \(hourCycle)" }
  }

  @Test(arguments: [
    TimeRangeCase(
      language: .enUS,
      timeZone: "America/Los_Angeles",
      hourCycle: .oneToTwelve,
      range: "from 8:00\u{202F}AM to 10:00\u{202F}AM"),
    TimeRangeCase(
      language: .enUS,
      timeZone: "America/Los_Angeles",
      hourCycle: .zeroToTwentyThree,
      range: "from 08:00 to 10:00"),
    TimeRangeCase(
      language: .enUS,
      timeZone: "Asia/Tokyo",
      hourCycle: .oneToTwelve,
      range: "from 1:00\u{202F}AM to 3:00\u{202F}AM"),
    TimeRangeCase(language: .enUS, timeZone: "Asia/Tokyo", hourCycle: .zeroToTwentyThree, range: "from 01:00 to 03:00"),
    TimeRangeCase(language: .jaJP, timeZone: "Asia/Tokyo", hourCycle: .zeroToTwentyThree, range: "1:00から3:00まで"),
    TimeRangeCase(language: .jaJP, timeZone: "Asia/Tokyo", hourCycle: .oneToTwelve, range: "午前1:00から午前3:00まで"),
    TimeRangeCase(
      language: .deDE,
      timeZone: "America/Los_Angeles",
      hourCycle: .zeroToTwentyThree,
      range: "von 08:00 bis 10:00"),
  ])
  func `Times are written in the time zone and hour cycle passed in`(_ range: TimeRangeCase) throws {
    let writer: SentenceWriter = try Self.writer(
      range.language,
      timeZone: #require(TimeZone(identifier: range.timeZone)),
      hourCycle: range.hourCycle)

    let sentence = writer.sentence(for: Self.rotation, at: TestData.instant(hours: 0))

    #expect(sentence.contains(range.range), "\(sentence)")
  }

  // MARK: Tracking reminders

  @Test
  func `The Tracking reminders read in the Live Activity's two levels`() {
    #expect(TrackingReminder.nextSwitchNeedsRefresh.text(in: .enUS) == "The next switch needs a Refresh.")
    #expect(TrackingReminder.scheduleOutOfDate.text(in: .enUS) == "Schedule out of date, tap Refresh.")
  }
}
