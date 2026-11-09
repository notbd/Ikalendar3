//
//  InkEventKindTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaDesign

struct InkEventKindTests {
  @Test
  func `Each event card wears its event's name, icon and colour, and a Splatfest's is white`() async throws {
    let items: [EventItem] = try await Self.eventItems(.normalDay, at: "2026-10-20T13:10:00Z")
      + Self.eventItems(.splatfestSecondHalf, at: "2026-11-01T20:00:00Z")
      + Self.eventItems(.bigRun, at: "2026-09-07T12:00:00Z")
      + Self.eventItems(.eggstraWork, at: "2026-08-28T12:00:00Z")

    let kinds: [InkEventKind] = items.map(InkEventKind.init)

    #expect(kinds.contains(InkEventKind(label: .challenges, icon: .challenge, accent: InkAccent(.challenge))))
    #expect(kinds.contains(InkEventKind(label: .splatfest, icon: .splatfestBattle, accent: .splatfest)))
    #expect(kinds.contains(InkEventKind(label: .bigRun, icon: .bigRun, accent: InkAccent(.bigRun))))
    #expect(kinds.contains(InkEventKind(label: .eggstraWork, icon: .eggstraWork, accent: InkAccent(.eggstraWork))))
  }

  /// The events of a recorded schedules feed at `instant`.
  static private func eventItems(_ fixture: Fixture, at instant: String) async throws -> [EventItem] {
    let feed: ScheduleFeed = try await ScheduleFeed.decode(from: fixture.data())
    let now: Date = try Date(instant, strategy: .iso8601)
    let snapshot: Snapshot = .init(schedules: .init(content: feed, fetchTime: now))
    return try #require(snapshot.eventItems(at: now))
  }
}
