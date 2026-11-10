//
//  TestData.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
@testable import IkaCore

// MARK: - TestData

/// Deterministic items at whole hours from a fixed epoch, for the cases no recorded fixture has.
enum TestData {
  /// 2026-01-01 00:00 UTC: an even UTC hour, like every Rotation boundary.
  static let epoch: Date = date("2026-01-01T00:00:00Z")

  /// The instant `hours` after the epoch.
  static func instant(hours: Double) -> Date {
    epoch.addingTimeInterval(hours * 3600)
  }

  /// A Regular Battle Rotation over `hours` from the epoch, paused or playing Turf War.
  static func rotation(hours: Range<Int>, isPaused: Bool = false) -> Rotation {
    Rotation(
      mode: .battle(.regular),
      startTime: instant(hours: Double(hours.lowerBound)),
      endTime: instant(hours: Double(hours.upperBound)),
      setting: isPaused ? nil : .init(rule: RuleID("VnNSdWxlLTA="), stages: [StageID("VnNTdGFnZS0x")]))
  }

  /// A schedules feed holding only `rotations`, in Regular Battle, with no Splatfest.
  static func feed(
    regularBattle rotations: [Rotation],
    failedSections: Set<ScheduleFeed.Section> = [])
    -> ScheduleFeed
  {
    ScheduleFeed(
      rotationsByMode: [.battle(.regular): rotations],
      challenges: [],
      salmonRun: [],
      eggstraWork: [],
      currentSplatfest: nil,
      terms: TermTable(),
      failedSections: failedSections)
  }
}
