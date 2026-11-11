//
//  ModeNameAndFormTests.swift
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
struct ModeNameAndFormTests {
  @Test
  func `Anarchy Battle's forms show the Mode's name over the form`() {
    #expect(ModeNameAndForm(.battle(.anarchySeries)) == ModeNameAndForm(name: .anarchyBattle, form: .series))
    #expect(ModeNameAndForm(.battle(.anarchyOpen)) == ModeNameAndForm(name: .anarchyBattle, form: .open))
  }

  @Test
  func `Modes with one form show their name alone`() {
    #expect(ModeNameAndForm(.battle(.regular)) == ModeNameAndForm(name: .regularBattle, form: nil))
    #expect(ModeNameAndForm(.battle(.x)) == ModeNameAndForm(name: .xBattle, form: nil))
    #expect(ModeNameAndForm(.salmonRun) == ModeNameAndForm(name: .salmonRun, form: nil))
  }

  @Test
  func `Splatfest Battle shows its name over the form the player chose`() {
    #expect(ModeNameAndForm(splatfestBattle: .open) == ModeNameAndForm(name: .splatfestBattle, form: .open))
    #expect(ModeNameAndForm(splatfestBattle: .pro) == ModeNameAndForm(name: .splatfestBattle, form: .pro))
  }

  @Test
  func `A summary heads as its Mode, a running Big Run as one`() async throws {
    let snapshot = try await Snapshot(
      schedules: Fetched(content: ScheduleFeed.decode(from: Fixture.bigRun.data()), fetchTime: .distantPast))
    let duringBigRun = try #require(snapshot.summary(of: .salmonRun, at: date("2026-09-13T00:00:00Z")))
    let afterBigRun = try #require(snapshot.summary(of: .salmonRun, at: date("2026-09-15T00:00:00Z")))
    let series = try #require(snapshot.summary(of: .battle(.anarchySeries), at: date("2026-09-13T00:00:00Z")))

    #expect(ModeNameAndForm(duringBigRun) == ModeNameAndForm(name: .bigRun, form: nil))
    #expect(ModeNameAndForm(afterBigRun) == ModeNameAndForm(.salmonRun))
    #expect(ModeNameAndForm(series) == ModeNameAndForm(.battle(.anarchySeries)))
    #expect(ModeNameAndForm(.splatfestBattle(.pro, .nothingCurrent)) == ModeNameAndForm(splatfestBattle: .pro))
  }

  @Test
  func `The Challenge screen shows the Challenges heading alone`() {
    #expect(ModeNameAndForm.challenges == ModeNameAndForm(name: .challenges, form: nil))
  }
}
