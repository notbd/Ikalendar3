//
//  NowPageTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

/// The 2026-10-31 Splatfest runs from 2026-10-31 00:00 UTC to 2026-11-02 00:00 UTC.
struct NowPageTests {
  @Test
  func `The Now page lists the five Modes' pages in the Mode value's order`() async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let instant = date("2026-10-20T13:30:00Z")

    let page = try #require(snapshot.nowPage(at: instant))

    #expect(page.modePages.map(\.mode) == Mode.allCases)
    #expect(page.modePages.map(\.summary) == Mode.allCases.compactMap { snapshot.summary(of: $0, at: instant) })
    #expect(page.splatfest == nil)
    #expect(page.fetchTime == TestData.epoch)
  }

  /// A Splatfest fixture at an instant, and whether the Splatfest shows on top there.
  struct SplatfestMoment: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let showsSplatfest: Bool

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  @Test(arguments: [
    SplatfestMoment(fixture: .splatfestAnnounced, instant: "2026-10-30T12:00:00Z", showsSplatfest: false),
    SplatfestMoment(fixture: .splatfestFirstHalf, instant: "2026-10-31T00:00:00Z", showsSplatfest: true),
    SplatfestMoment(fixture: .splatfestFirstHalf, instant: "2026-10-31T12:00:00Z", showsSplatfest: true),
    SplatfestMoment(fixture: .splatfestSecondHalf, instant: "2026-11-01T05:23:00Z", showsSplatfest: true),
    SplatfestMoment(fixture: .splatfestSecondHalf, instant: "2026-11-01T23:59:59Z", showsSplatfest: true),
    SplatfestMoment(fixture: .splatfestSecondHalf, instant: "2026-11-02T00:00:00Z", showsSplatfest: false),
  ])
  func `The Splatfest shows on top from its start to its end, not while it is only announced`(
    _ moment: SplatfestMoment)
    async throws
  {
    let snapshot = try await Snapshot.schedules(moment.fixture)

    let page = try #require(snapshot.nowPage(at: date(moment.instant)))

    #expect(page.splatfest == (moment.showsSplatfest ? snapshot.splatfest : nil))
    #expect(page.splatfest?.startTime == (moment.showsSplatfest ? date("2026-10-31T00:00:00Z") : nil))
  }

  @Test
  func `During the Splatfest the four Battle Modes stay listed, paused until it ends`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)

    let page = try #require(snapshot.nowPage(at: date("2026-11-01T05:23:00Z")))

    let returnTime = date("2026-11-02T00:00:00Z")
    #expect(page.modePages.prefix(4).map(\.summary) == BattleMode.allCases.map {
      .battle($0, .paused(returnTime: returnTime))
    })
  }

  @Test
  func `No Now page exists before the schedules feed's first good response`() {
    #expect(Snapshot().nowPage(at: TestData.epoch) == nil)
  }
}
