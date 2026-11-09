//
//  ChallengeScreenTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

/// The normal day publishes two Challenges, each with six two-hour windows four hours apart:
/// the first on 2026-10-23 from 02:00 UTC, the second on 2026-10-30 from 02:00 UTC.
struct ChallengeScreenTests {
  /// An instant on the normal day and the marks of each listed Challenge's six windows.
  struct MarkCase: CustomTestStringConvertible {
    let instant: String
    let marks: [[ChallengeScreen.WindowMark]]

    var testDescription: String { instant }
  }

  @Test(arguments: [
    // Inside the first window, an hour in.
    MarkCase(instant: "2026-10-23T03:00:00Z", marks: [
      [.current(.init(timeLeft: .seconds(3600), sharePassed: 0.5)), .next, .later, .later, .later, .later],
      [.later, .later, .later, .later, .later, .later],
    ]),
    // In the gap after the first window.
    MarkCase(instant: "2026-10-23T04:00:00Z", marks: [
      [.over, .next, .later, .later, .later, .later],
      [.later, .later, .later, .later, .later, .later],
    ]),
    // In the first Challenge's last window: the next window is the second Challenge's first.
    MarkCase(instant: "2026-10-23T23:30:00Z", marks: [
      [.over, .over, .over, .over, .over, .current(.init(timeLeft: .seconds(1800), sharePassed: 0.75))],
      [.next, .later, .later, .later, .later, .later],
    ]),
    // Before either Challenge.
    MarkCase(instant: "2026-10-20T12:00:00Z", marks: [
      [.next, .later, .later, .later, .later, .later],
      [.later, .later, .later, .later, .later, .later],
    ]),
  ])
  func `The Challenge screen lists both published Challenges with every window marked`(
    _ markCase: MarkCase)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let published = try #require(snapshot.schedules?.content.challenges)

    let screen = try #require(snapshot.challengeScreen(at: date(markCase.instant)))

    #expect(screen.challenges.map(\.challenge) == published)
    #expect(screen.challenges.map { $0.windows.map(\.window) } == published.map(\.windows))
    #expect(screen.challenges.map { $0.windows.map(\.mark) } == markCase.marks)
  }

  @Test
  func `A Challenge whose last window has ended leaves the screen`() async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let second = try #require(snapshot.schedules?.content.challenges.last)

    let screen = try #require(snapshot.challengeScreen(at: date("2026-10-26T00:00:00Z")))

    #expect(screen.challenges.map(\.challenge) == [second])
    #expect(screen.challenges.first?.windows.map(\.mark) == [.next, .later, .later, .later, .later, .later])
  }

  @Test(arguments: ["2026-10-31T00:00:00Z", "2026-11-05T00:00:00Z"])
  func `After the last window of the last published Challenge none is announced`(_ instant: String) async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)

    let screen = try #require(snapshot.challengeScreen(at: date(instant)))

    #expect(screen.challenges.isEmpty)
  }

  @Test
  func `The Challenge screen carries the fetch time of the schedules feed`() async throws {
    let fetchTime = date("2026-10-20T12:03:00Z")
    let snapshot = try await Snapshot.schedules(.normalDay, fetchedAt: fetchTime)

    #expect(snapshot.challengeScreen(at: date("2026-10-20T12:03:00Z"))?.fetchTime == fetchTime)
    #expect(Snapshot().challengeScreen(at: TestData.epoch) == nil)
  }
}
