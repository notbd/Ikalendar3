//
//  ScreenIndependenceTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - ScreenIndependenceTests

struct ScreenIndependenceTests {
  @Test(arguments: [
    ScheduleFeed.Section.rotations(.battle(.x)),
    .rotations(.battle(.anarchySeries)),
    .salmonRun,
    .eggstraWork,
  ])
  func `One failed Schedule leaves every other screen's content intact`(_ failed: ScheduleFeed.Section) async throws {
    // Every Schedule has an item on at this instant, the Eggstra Work included.
    let instant = date("2026-08-29T12:00:00Z")
    let feed = try await ScheduleFeed.decode(from: Fixture.eggstraWork.data())
    let intact: Snapshot = .schedules(feed)
    let broken: Snapshot = .schedules(feed.emptying(failed))

    for mode in BattleMode.allCases {
      let screen = try #require(broken.battleScreen(of: mode, at: instant))
      if failed == .rotations(.battle(mode)) {
        #expect(screen.current == .nothingCurrent)
        #expect(screen.next == nil)
        #expect(screen.later.isEmpty)
      }
      else {
        #expect(screen == intact.battleScreen(of: mode, at: instant), "\(mode)")
      }
    }

    let salmonRun = try #require(broken.salmonRunScreen(at: instant))
    let intactSalmonRun = try #require(intact.salmonRunScreen(at: instant))
    if failed == .salmonRun {
      #expect(salmonRun.current == .nothingCurrent)
      #expect(salmonRun.next == nil)
      #expect(salmonRun.later.isEmpty)
    }
    else {
      #expect(salmonRun.current == intactSalmonRun.current)
      #expect(salmonRun.next == intactSalmonRun.next)
      #expect(salmonRun.later == intactSalmonRun.later)
    }
    #expect(salmonRun.eggstraWork == (failed == .eggstraWork ? nil : intactSalmonRun.eggstraWork))
  }
}

extension ScheduleFeed {
  /// The feed with `section` empty and reported failed, as when that part fails to decode.
  fileprivate func emptying(_ section: Section) -> ScheduleFeed {
    var rotationsByMode = rotationsByMode
    if case .rotations(let mode) = section {
      rotationsByMode[mode] = []
    }
    return ScheduleFeed(
      rotationsByMode: rotationsByMode,
      challenges: section == .challenges ? [] : challenges,
      salmonRun: section == .salmonRun ? [] : salmonRun,
      eggstraWork: section == .eggstraWork ? [] : eggstraWork,
      currentSplatfest: section == .splatfest ? nil : currentSplatfest,
      terms: terms,
      failedSections: failedSections.union([section]))
  }
}
