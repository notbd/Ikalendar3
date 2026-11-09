//
//  ChallengeLineupTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

/// The normal day publishes two Challenges, each with six two-hour windows four hours apart:
/// the first on 2026-10-23 from 02:00 UTC, the second on 2026-10-30 from 02:00 UTC.
struct ChallengeLineupTests {
  static let first: ChallengeID = .init("TGVhZ3VlTWF0Y2hFdmVudC1XZWFwb25MaW1pdGVkX01hbmV1dmVy")
  static let second: ChallengeID = .init("TGVhZ3VlTWF0Y2hFdmVudC1Sb2xsZXJCcnVzaFNwZWVkVXA=")

  /// An instant and the windows its lineup holds, by Challenge and start time.
  struct WindowCase: CustomTestStringConvertible {
    let instant: String
    /// The window on, or `nil` for a gap.
    let current: (challenge: ChallengeID, start: String)?
    let next: (challenge: ChallengeID, start: String)
    let laterCount: Int

    var testDescription: String { instant }
  }

  @Test(arguments: [
    WindowCase(
      instant: "2026-10-23T03:00:00Z",
      current: (first, "2026-10-23T02:00:00Z"),
      next: (first, "2026-10-23T06:00:00Z"),
      laterCount: 10),
    WindowCase(
      instant: "2026-10-23T22:00:00Z",
      current: (first, "2026-10-23T22:00:00Z"),
      next: (second, "2026-10-30T02:00:00Z"),
      laterCount: 5),
    WindowCase(
      instant: "2026-10-20T12:00:00Z",
      current: nil,
      next: (first, "2026-10-23T02:00:00Z"),
      laterCount: 11),
    WindowCase(
      instant: "2026-10-23T04:00:00Z",
      current: nil,
      next: (first, "2026-10-23T06:00:00Z"),
      laterCount: 10),
    WindowCase(
      instant: "2026-10-23T05:59:59Z",
      current: nil,
      next: (first, "2026-10-23T06:00:00Z"),
      laterCount: 10),
    WindowCase(
      instant: "2026-10-26T00:00:00Z",
      current: nil,
      next: (second, "2026-10-30T02:00:00Z"),
      laterCount: 5),
  ])
  func `Challenges hold the window on, or a gap, and the next window of any published Challenge`(
    _ window: WindowCase)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    let lineup = feed.challengeLineup(at: date(window.instant))

    if let current = window.current {
      let item = try #require(lineup.current.item)
      #expect(item.challenge.id == current.challenge)
      #expect(item.startTime == date(current.start))
      #expect(item.endTime == date(current.start).addingTimeInterval(2 * 3600))
    }
    else {
      #expect(lineup.current == .gap)
    }
    let next = try #require(lineup.next)
    #expect(next.challenge.id == window.next.challenge)
    #expect(next.startTime == date(window.next.start))
    #expect(lineup.later.count == window.laterCount)
    #expect(lineup.later.map(\.startTime) == lineup.later.map(\.startTime).sorted())
  }

  @Test(arguments: ["2026-10-31T00:00:00Z", "2026-11-05T00:00:00Z"])
  func `Challenges past the last window of the last published Challenge have none announced`(
    _ instant: String)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    #expect(feed.challengeLineup(at: date(instant)) == Lineup(current: .noneAnnounced, next: nil, later: []))
  }
}
