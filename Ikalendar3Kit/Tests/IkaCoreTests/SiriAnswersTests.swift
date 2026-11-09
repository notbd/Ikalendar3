//
//  SiriAnswersTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct SiriAnswersTests {
  /// The answers over a fixture's schedules feed in en-US, Los Angeles time unless another is
  /// given, and the 12-hour cycle.
  static func answers(
    _ fixture: Fixture,
    language: GameLanguage = .enUS,
    timeZone: TimeZone = losAngeles)
    async throws -> SiriAnswers
  {
    let feed = try await ScheduleFeed.decode(from: fixture.data())
    return answers(feed, language: language, timeZone: timeZone)
  }

  static func answers(
    _ feed: ScheduleFeed?,
    language: GameLanguage = .enUS,
    timeZone: TimeZone = losAngeles)
    -> SiriAnswers
  {
    SiriAnswers(
      snapshot: Snapshot(schedules: feed.map { Fetched(content: $0, fetchTime: .distantPast) }),
      language: language,
      timeZone: timeZone,
      hourCycle: .oneToTwelve)
  }

  static let losAngeles: TimeZone = .init(identifier: "America/Los_Angeles")!

  // MARK: Now

  @Test
  func `Now in a Battle Mode reads the Rotation on now with its time left`() async throws {
    let answers = try await Self.answers(.normalDay)

    #expect(answers.now(in: .battle(.x), at: date("2026-10-20T13:00:00Z")) ==
      "X Battle: Tower Control on Mahi-Mahi Resort and Robo ROM-en, "
      + "from 5:00\u{202F}AM to 7:00\u{202F}AM, 1 hour left.")
  }

  @Test
  func `Now in Salmon Run and the current Shift read the Shift on now`() async throws {
    let answers = try await Self.answers(.normalDay)
    let instant: Date = date("2026-10-20T13:00:00Z")

    let shift = "Salmon Run: Jammin' Salmon Junction with S-BLAST '92, Splat Dualies, Splash-o-matic, and Goo Tuber, "
      + "from Sunday 5:00\u{202F}PM to Tuesday 9:00\u{202F}AM, 3 hours left."
    #expect(answers.now(in: .salmonRun, at: instant) == shift)
    #expect(answers.currentShift(at: instant) == shift)
  }

  /// The fixture's regular Shift hands out four golden random marks.
  @Test
  func `The current Shift is the regular one while an Eggstra Work runs beside it`() async throws {
    let answers = try await Self.answers(.eggstraWork)

    #expect(answers.currentShift(at: date("2026-08-29T12:00:00Z")) ==
      "Salmon Run: Spawning Grounds with Rare Random, Rare Random, Rare Random, and Rare Random, "
      + "from Friday 1:00\u{202F}AM to Saturday 5:00\u{202F}PM, 12 hours left.")
  }

  // MARK: Next

  @Test
  func `Next in a Mode reads the item after the one on now, with no time left`() async throws {
    let answers = try await Self.answers(.normalDay)
    let instant: Date = date("2026-10-20T13:00:00Z")

    #expect(answers.next(in: .battle(.regular), at: instant) ==
      "Regular Battle: Turf War on Hammerhead Bridge and Inkblot Art Academy, from 7:00\u{202F}AM to 9:00\u{202F}AM.")
    #expect(answers.next(in: .salmonRun, at: instant) ==
      "Salmon Run: Spawning Grounds with Splatana Wiper, N-ZAP '85, Splattershot Jr., and Tri-Stringer, "
      + "from Tuesday 9:00\u{202F}AM to Thursday 1:00\u{202F}AM.")
  }

  @Test
  func `Next past the last published item is not in the published Schedule`() async throws {
    let answers = try await Self.answers(.normalDay)

    #expect(answers.next(in: .battle(.anarchyOpen), at: date("2026-10-21T11:00:00Z")) ==
      "Anarchy Battle (Open): what comes next is not in the published Schedule yet.")
    #expect(answers.next(in: .salmonRun, at: date("2026-10-26T00:00:00Z")) ==
      "Salmon Run: what comes next is not in the published Schedule yet.")
  }

  // MARK: Rules

  @Test
  func `A Rule reads the first Rotation from now on that plays it`() async throws {
    let answers = try await Self.answers(.normalDay)
    let instant: Date = date("2026-10-20T13:00:00Z")

    #expect(answers.next(Self.clamBlitz, in: .anarchySeries, at: instant) ==
      "Anarchy Battle (Series): Clam Blitz on Brinewater Springs and Lemuria Hub, "
      + "from 11:00\u{202F}AM to 1:00\u{202F}PM.")
    #expect(answers.next(Self.rainmaker, in: .anarchySeries, at: instant) ==
      "Anarchy Battle (Series): Rainmaker on Um'ami Ruins and Museum d'Alfonsino, "
      + "from 5:00\u{202F}AM to 7:00\u{202F}AM, 1 hour left.")
  }

  /// Council round 5, P1: a Rotation up to a day ahead reads its weekday, so 3:00 AM asked at
  /// 5:30 AM is not taken for a time already past.
  @Test
  func `A Rule's Rotation on a later day reads its weekday`() throws {
    let splatZones: RuleID = .init("VnNSdWxlLTE=")
    let rotations = stride(from: 12, to: 36, by: 2).map { hour in
      Rotation(
        mode: .battle(.regular),
        startTime: TestData.instant(hours: Double(hour)),
        endTime: TestData.instant(hours: Double(hour + 2)),
        setting: .init(rule: hour == 34 ? splatZones : Self.turfWar, stages: [StageID("VnNTdGFnZS0x")]))
    }
    let denver = try #require(TimeZone(identifier: "America/Denver"))
    let answers: SiriAnswers = Self.answers(TestData.feed(regularBattle: rotations), timeZone: denver)

    // 12:30 UTC on Thursday is 5:30 AM in Denver; Friday's 10:00 UTC is 3:00 AM.
    #expect(answers.next(splatZones, in: .regular, at: TestData.instant(hours: 12.5)) ==
      "Regular Battle: Splat Zones on Scorch Gorge, from Friday 3:00\u{202F}AM to 5:00\u{202F}AM.")
  }

  @Test
  func `A Rule absent from the remaining Rotations is not in the published Schedule`() async throws {
    let answers = try await Self.answers(.normalDay)

    #expect(answers.next(Self.turfWar, in: .x, at: date("2026-10-20T13:00:00Z")) ==
      "X Battle: Turf War is not in the published Schedule.")
  }

  // MARK: Splatfest pause

  /// The recorded decision: a Battle Mode a Splatfest pauses says when it comes back. Next and
  /// a Rule read the first Rotation after the Splatfest once it is published, after the pause;
  /// asked Saturday night, the Rotation reads its start's weekday, Sunday.
  @Test
  func `A paused Battle Mode says when it comes back`() async throws {
    let secondHalf = try await Self.answers(.splatfestSecondHalf)
    let firstHalf = try await Self.answers(.splatfestFirstHalf)
    let comesBack = "Regular Battle: paused during the Splatfest until Sunday 4:00\u{202F}PM."
    let firstAfter = comesBack
      + " Regular Battle: Turf War on Mincemeat Metalworks and Inkblot Art Academy,"
      + " from Sunday 4:00\u{202F}PM to 6:00\u{202F}PM."

    #expect(secondHalf.now(in: .battle(.regular), at: date("2026-11-01T06:00:00Z")) == comesBack)
    #expect(secondHalf.next(in: .battle(.regular), at: date("2026-11-01T06:00:00Z")) == firstAfter)
    #expect(secondHalf.next(Self.turfWar, in: .regular, at: date("2026-11-01T06:00:00Z")) == firstAfter)
    #expect(firstHalf.next(in: .battle(.regular), at: date("2026-10-31T13:00:00Z")) == comesBack)
    #expect(firstHalf.next(Self.turfWar, in: .regular, at: date("2026-10-31T13:00:00Z")) == comesBack)
  }

  /// Council round 5 (Sol): a Rule's Rotation that starts after midnight following the return
  /// reads its own weekday; the pause's weekday is the return's day, not the Rotation's.
  @Test
  func `A Rule's Rotation the day after the Splatfest's return reads its own weekday`() async throws {
    let noronha = try #require(TimeZone(identifier: "America/Noronha"))
    let answers = try await Self.answers(.splatfestSecondHalf, timeZone: noronha)

    #expect(answers.next(Self.rainmaker, in: .x, at: date("2026-11-01T06:00:00Z")) ==
      "X Battle: paused during the Splatfest until Sunday 10:00\u{202F}PM."
      + " X Battle: Rainmaker on Um'ami Ruins and Barnacle & Dime, from Monday 12:00\u{202F}AM to 2:00\u{202F}AM.")
  }

  /// Ticket 21: a Rule absent from the remaining Rotations is not published, a pause or not.
  @Test
  func `A Rule no published Rotation after the Splatfest plays is not in the published Schedule`() async throws {
    let answers = try await Self.answers(.splatfestSecondHalf)
    let instant: Date = date("2026-11-01T06:00:00Z")

    #expect(answers.next(Self.rainmaker, in: .regular, at: instant) ==
      "Regular Battle: Rainmaker is not in the published Schedule.")
    #expect(answers.next(Self.turfWar, in: .x, at: instant) == "X Battle: Turf War is not in the published Schedule.")
  }

  /// The feed publishes the paused windows that follow, so the Schedule does reach that far.
  @Test
  func `In the last Rotation before a Splatfest, what comes next is the pause`() async throws {
    let answers = try await Self.answers(.splatfestAnnounced)
    let instant: Date = date("2026-10-30T23:00:00Z")

    #expect(answers.next(in: .battle(.regular), at: instant) ==
      "Regular Battle: paused during the Splatfest until Sunday 4:00\u{202F}PM.")
    #expect(answers.next(Self.rainmaker, in: .x, at: instant) ==
      "X Battle: paused during the Splatfest until Sunday 4:00\u{202F}PM.")
    #expect(answers.next(Self.clamBlitz, in: .x, at: instant) ==
      "X Battle: Clam Blitz on Um'ami Ruins and Sturgeon Shipyard, from 3:00\u{202F}PM to 5:00\u{202F}PM, 1 hour left.")
  }

  // MARK: Big Run and Splatfest

  @Test
  func `With no Big Run or Splatfest in the feed, none is announced`() async throws {
    let answers = try await Self.answers(.normalDay)

    #expect(answers.nextBigRunAndSplatfest(at: date("2026-10-20T13:00:00Z")) ==
      "Big Run: none announced yet. Splatfest: none announced yet.")
  }

  @Test
  func `A Big Run in the feed reads its Shift with its start time`() async throws {
    let answers = try await Self.answers(.bigRun)

    #expect(answers.nextBigRunAndSplatfest(at: date("2026-09-07T13:00:00Z")) ==
      "Big Run: Wahoo World with Random, Random, Random, and Random, "
      + "from Friday 5:00\u{202F}PM to Sunday 5:00\u{202F}PM. Splatfest: none announced yet.")
  }

  @Test
  func `An announced Splatfest reads its title and dates`() async throws {
    let answers = try await Self.answers(.splatfestAnnounced)

    #expect(answers.nextBigRunAndSplatfest(at: date("2026-10-30T13:00:00Z")) ==
      "Big Run: none announced yet. Splatfest: “What would you be in a fantasy world?”, "
      + "from Friday, October 30 at 5:00\u{202F}PM to Sunday, November 1 at 4:00\u{202F}PM.")
  }

  // MARK: Out of date

  @Test
  func `Past the cached Schedule's end, every answer is out of date`() async throws {
    let answers = try await Self.answers(.normalDay)
    let instant: Date = date("2026-10-28T00:00:00Z")

    #expect(answers.now(in: .battle(.regular), at: instant) == "Regular Battle: the Schedule is out of date.")
    #expect(answers.next(in: .battle(.regular), at: instant) == "Regular Battle: the Schedule is out of date.")
    #expect(answers.next(Self.clamBlitz, in: .x, at: instant) == "X Battle: the Schedule is out of date.")
    #expect(answers.currentShift(at: instant) == "Salmon Run: the Schedule is out of date.")
    #expect(answers.nextBigRunAndSplatfest(at: instant) ==
      "Big Run: the Schedule is out of date. Splatfest: the Schedule is out of date.")
  }

  @Test
  func `With no cached Schedule yet, answers are out of date`() {
    let answers: SiriAnswers = Self.answers(nil)

    #expect(answers.now(in: .salmonRun, at: TestData.epoch) == "Salmon Run: the Schedule is out of date.")
  }

  @Test
  func `A Splatfest that failed to decode is out of date, not none announced`() {
    let rotations = [TestData.rotation(hours: 0 ..< 2)]
    let decoded: SiriAnswers = Self.answers(TestData.feed(regularBattle: rotations))
    let failed: SiriAnswers = Self.answers(TestData.feed(regularBattle: rotations, failedSections: [.splatfest]))

    #expect(decoded.nextBigRunAndSplatfest(at: TestData.epoch).hasSuffix("Splatfest: none announced yet."))
    #expect(failed.nextBigRunAndSplatfest(at: TestData.epoch).hasSuffix("Splatfest: the Schedule is out of date."))
  }

  // MARK: Languages

  @Test(arguments: GameLanguage.allCases)
  func `Every answer template resolves in each language`(language: GameLanguage) async throws {
    let normalDay = try await Self.answers(.normalDay, language: language)
    let paused = try await Self.answers(.splatfestFirstHalf, language: language)
    let announced = try await Self.answers(.splatfestAnnounced, language: language)
    let notYet: SiriAnswers = Self.answers(
      TestData.feed(regularBattle: [TestData.rotation(hours: 2 ..< 4)]),
      language: language)
    let today: Date = date("2026-10-20T13:00:00Z")
    let lastRotation: Date = date("2026-10-21T11:00:00Z")
    let later: Date = date("2026-10-28T00:00:00Z")

    let texts = [
      normalDay.now(in: .battle(.anarchyOpen), at: today),
      normalDay.next(in: .salmonRun, at: today),
      normalDay.next(in: .battle(.x), at: lastRotation),
      normalDay.next(Self.turfWar, in: .x, at: today),
      normalDay.now(in: .battle(.regular), at: later),
      normalDay.nextBigRunAndSplatfest(at: today),
      paused.now(in: .battle(.anarchySeries), at: date("2026-10-31T13:00:00Z")),
      announced.nextBigRunAndSplatfest(at: date("2026-10-30T13:00:00Z")),
      notYet.now(in: .battle(.regular), at: TestData.epoch),
    ]

    for text in texts {
      #expect(!text.isEmpty && !text.contains("%") && !text.contains(".."), "\(language.rawValue): \(text)")
      for key in ["answer.", "sentence.", "mode."] {
        #expect(!text.contains(key), "\(language.rawValue): \(text)")
      }
    }
    if ![.enUS, .enGB].contains(language) {
      let english = try await Self.answers(.normalDay).nextBigRunAndSplatfest(at: today)
      #expect(texts[5] != english)
    }
  }

  // MARK: Rules by Nintendo's id

  static let turfWar: RuleID = .init("VnNSdWxlLTA=")
  static let rainmaker: RuleID = .init("VnNSdWxlLTM=")
  static let clamBlitz: RuleID = .init("VnNSdWxlLTQ=")
}
