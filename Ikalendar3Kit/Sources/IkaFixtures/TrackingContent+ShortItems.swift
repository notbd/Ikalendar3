//
//  TrackingContent+ShortItems.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import Foundation
import IkaCore

extension TrackingContent {
  /// The same items, back to back from `start`, each lasting two minutes: the short-item fixture,
  /// so a recording crosses two boundaries in minutes instead of hours. IDs stay as carried.
  public func withShortItems(startingAt start: Date) -> TrackingContent {
    func startTime(of index: Int) -> Date {
      start.addingTimeInterval(Self.shortItemLength * Double(index))
    }

    switch self {
      case .battle(let mode, let rotations):
        return .battle(mode, rotations.enumerated().map { index, rotation in
          TrackedRotation(startTime: startTime(of: index), endTime: startTime(of: index + 1), setting: rotation.setting)
        })

      case .salmonRun(let shifts):
        return .salmonRun(shifts.enumerated().map { index, shift in
          TrackedShift(
            startTime: startTime(of: index),
            endTime: startTime(of: index + 1),
            isBigRun: shift.isBigRun,
            stage: shift.stage,
            weapons: shift.weapons)
        })
    }
  }

  /// How long each item of the short-item fixture lasts.
  static private let shortItemLength: TimeInterval = 2 * 60
}
#endif
