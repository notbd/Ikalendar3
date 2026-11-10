//
//  InkModeHeadingTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaDesign

/// Pins how Ink names a Mode over its list: the Mode's name, with Anarchy Battle's form on a tag.
struct InkModeHeadingTests {
  @Test
  func `Anarchy Battle's forms show the Mode's name over the form`() {
    #expect(InkModeHeading(.battle(.anarchySeries)) == InkModeHeading(name: .anarchyBattle, form: .series))
    #expect(InkModeHeading(.battle(.anarchyOpen)) == InkModeHeading(name: .anarchyBattle, form: .open))
  }

  @Test
  func `Modes with one form show their name alone`() {
    #expect(InkModeHeading(.battle(.regular)) == InkModeHeading(name: .regularBattle, form: nil))
    #expect(InkModeHeading(.battle(.x)) == InkModeHeading(name: .xBattle, form: nil))
    #expect(InkModeHeading(.salmonRun) == InkModeHeading(name: .salmonRun, form: nil))
  }

  @Test
  func `Splatfest Battle shows its name over the form the player chose`() {
    #expect(InkModeHeading(splatfestBattle: .open) == InkModeHeading(name: .splatfestBattle, form: .open))
    #expect(InkModeHeading(splatfestBattle: .pro) == InkModeHeading(name: .splatfestBattle, form: .pro))
  }

  @Test
  func `A summary heads as its Mode, a running Big Run as one`() async throws {
    let snapshot = try await Snapshot(
      schedules: Fetched(content: ScheduleFeed.decode(from: Fixture.bigRun.data()), fetchTime: .distantPast))
    let duringBigRun = try #require(snapshot.summary(of: .salmonRun, at: date("2026-09-13T00:00:00Z")))
    let afterBigRun = try #require(snapshot.summary(of: .salmonRun, at: date("2026-09-15T00:00:00Z")))
    let series = try #require(snapshot.summary(of: .battle(.anarchySeries), at: date("2026-09-13T00:00:00Z")))

    #expect(InkModeHeading(duringBigRun) == InkModeHeading(name: .bigRun, form: nil))
    #expect(InkModeHeading(afterBigRun) == InkModeHeading(.salmonRun))
    #expect(InkModeHeading(series) == InkModeHeading(.battle(.anarchySeries)))
    #expect(InkModeHeading(.splatfestBattle(.pro, .nothingCurrent)) == InkModeHeading(splatfestBattle: .pro))
  }

  @Test
  func `The Challenge screen shows the Challenges heading alone`() {
    #expect(InkModeHeading.challenges == InkModeHeading(name: .challenges, form: nil))
  }
}
