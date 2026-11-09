//
//  ModePageTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct ModePageTests {
  @Test(arguments: Mode.allCases)
  func `Every Mode has a page showing its own screen`(_ mode: Mode) async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let instant = date("2026-10-20T13:30:00Z")

    let page = try #require(snapshot.modePage(of: mode, at: instant))

    let screen: ModePage? =
      switch mode {
        case .battle(let battleMode): snapshot.battleScreen(of: battleMode, at: instant).map(ModePage.battle)
        case .salmonRun: snapshot.salmonRunScreen(at: instant).map(ModePage.salmonRun)
      }
    #expect(page.mode == mode)
    #expect(page == screen)
  }

  @Test
  func `A Battle Mode page holds the next and later Rotations as published`() async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let published = try #require(snapshot.schedules?.content.rotations(for: .battle(.x)))

    let page = snapshot.modePage(of: .battle(.x), at: date("2026-10-20T13:30:00Z"))

    guard case .battle(let screen) = page else {
      Issue.record("No Battle Mode page in \(String(describing: page))")
      return
    }

    #expect(screen.next == published[1])
    #expect(screen.later == Array(published.dropFirst(2)))
  }

  @Test
  func `The Salmon Run page holds a Big Run among the Shifts in time order`() async throws {
    let snapshot = try await Snapshot.schedules(.bigRun)

    let page = snapshot.modePage(of: .salmonRun, at: date("2026-09-07T12:00:00Z"))

    guard case .salmonRun(let screen) = page else {
      Issue.record("No Salmon Run page in \(String(describing: page))")
      return
    }

    let upcoming = [screen.next].compactMap(\.self) + screen.later
    #expect(upcoming.map(\.kind) == [.regular, .regular, .bigRun, .regular])
    #expect(upcoming.map(\.startTime) == upcoming.map(\.startTime).sorted())
  }

  /// Ticket 08's decision: a Battle Mode the Splatfest pauses reports its pause with its return
  /// time; its next Rotation is the first one after the Splatfest.
  @Test(arguments: BattleMode.allCases)
  func `During the Splatfest a Battle Mode page reports its return and the Rotation after it`(
    _ mode: BattleMode)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let returnTime = date("2026-11-02T00:00:00Z")

    let page = snapshot.modePage(of: .battle(mode), at: date("2026-11-01T05:23:00Z"))

    #expect(page?.summary == .battle(mode, .paused(returnTime: returnTime)))
    if case .battle(let screen) = page, let next = screen.next {
      #expect(returnTime <= next.startTime)
    }
  }

  @Test(arguments: Mode.allCases)
  func `No Mode page exists before the schedules feed's first good response`(_ mode: Mode) {
    #expect(Snapshot().modePage(of: mode, at: TestData.epoch) == nil)
  }
}
