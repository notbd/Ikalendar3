//
//  TrackingContent.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - TrackingContent

/// What a Live Activity carries while Tracking a Mode: the item on when it was built and up to
/// the next two in the Mode's Schedule, back to back, each with its real start and end.
///
/// It holds ids and times only, so it stays far under ActivityKit's 4 KB; names and images
/// resolve at render time.
public enum TrackingContent: Codable, Hashable, Sendable {
  /// A Battle Mode's Rotations.
  case battle(BattleMode, [TrackedRotation])
  /// Salmon Run's Shifts: its regular Shifts and Big Runs, never an Eggstra Work.
  case salmonRun([TrackedShift])

  /// The tracked Mode.
  public var mode: Mode {
    switch self {
      case .battle(let mode, _): .battle(mode)
      case .salmonRun: .salmonRun
    }
  }

  /// When the item on at build time ends: every update sets the activity's stale date here, so
  /// the system renders the next item once with no app code running. `nil` when nothing was on.
  public var staleDate: Date? {
    switch self {
      case .battle(_, let rotations): rotations.first?.endTime
      case .salmonRun(let shifts): shifts.first?.endTime
    }
  }

  /// When Tracking started at `startTime` ends: eight hours later, the longest the system lets a
  /// Live Activity run. It then leaves the Dynamic Island; the system may keep it on the Lock
  /// Screen up to four more hours.
  static public func endDate(startedAt startTime: Date) -> Date {
    startTime.addingTimeInterval(8 * 3600)
  }
}

// MARK: - TrackedRotation

/// A Battle Mode's item in Tracking: a Rotation by its Rule and Stages, or a Splatfest's pause.
///
/// A Splatfest pause is one item from the Splatfest's start until the Battle Mode returns, so a
/// view says when it comes back, as the iPhone tabs do. Tracking started during a Splatfest
/// shows the pause first; Tracking that runs into one switches to the pause at its start on its
/// own, like at any boundary.
public struct TrackedRotation: TimeWindow, Codable, Hashable, Sendable {
  /// When the item starts.
  public let startTime: Date
  /// When the item ends: for a pause, when the Battle Mode returns.
  public let endTime: Date
  /// The Rule and Stages played, or `nil` for a Splatfest's pause.
  public let setting: Rotation.Setting?

  public init(startTime: Date, endTime: Date, setting: Rotation.Setting?) {
    self.startTime = startTime
    self.endTime = endTime
    self.setting = setting
  }

  /// Whether a Splatfest pauses the Battle Mode during this item.
  public var isPaused: Bool { setting == nil }
}

extension TrackedRotation {
  /// The item of `rotation`.
  init(_ rotation: Rotation) {
    self.init(startTime: rotation.startTime, endTime: rotation.endTime, setting: rotation.setting)
  }
}

// MARK: - TrackedShift

/// Salmon Run's item in Tracking: a regular Shift or a Big Run by its Stage and weapons.
public struct TrackedShift: TimeWindow, Codable, Hashable, Sendable {
  /// When the Shift starts.
  public let startTime: Date
  /// When the Shift ends.
  public let endTime: Date
  /// Whether the Shift is a Big Run.
  public let isBigRun: Bool
  /// The Stage.
  public let stage: StageID
  /// The four weapons in the feed's order, random marks included.
  public let weapons: [WeaponID]

  public init(startTime: Date, endTime: Date, isBigRun: Bool, stage: StageID, weapons: [WeaponID]) {
    self.startTime = startTime
    self.endTime = endTime
    self.isBigRun = isBigRun
    self.stage = stage
    self.weapons = weapons
  }
}

extension TrackedShift {
  /// The item of `shift`, a regular Shift or a Big Run.
  init(_ shift: Shift) {
    self.init(
      startTime: shift.startTime,
      endTime: shift.endTime,
      isBigRun: shift.kind == .bigRun,
      stage: shift.stage,
      weapons: shift.weapons)
  }
}

// MARK: - Building

extension ScheduleFeed {
  /// The content of Tracking `mode` at `instant`.
  public func trackingContent(of mode: Mode, at instant: Date) -> TrackingContent {
    switch mode {
      case .battle(let battleMode):
        .battle(battleMode, Self.backToBack(from: instant) { trackedRotation(of: battleMode, at: $0) })

      case .salmonRun:
        .salmonRun(Self.backToBack(from: instant) { salmonRunLineup(at: $0).current.item.map(TrackedShift.init) })
    }
  }

  /// A Battle Mode's item on at `instant`: its Rotation, or the whole pause while a Splatfest
  /// pauses it. `nil` when none is.
  private func trackedRotation(of mode: BattleMode, at instant: Date) -> TrackedRotation? {
    switch battleLineup(of: .battle(mode), at: instant).current {
      case .item(let rotation):
        TrackedRotation(rotation)

      case .paused(let returnTime):
        TrackedRotation(startTime: pauseStart(of: .battle(mode), at: instant), endTime: returnTime, setting: nil)

      case .gap,
           .ranOut,
           .noneAnnounced:
        nil
    }
  }

  /// When the pause on at `instant` began: its Splatfest's start, or its first published paused
  /// window's when the Splatfest failed to decode.
  private func pauseStart(of mode: RotationMode, at instant: Date) -> Date {
    if let splatfest = runningSplatfest(at: instant) { return splatfest.startTime }

    let pausedSoFar = rotations(for: mode).filter { $0.startTime <= instant }.reversed().prefix(while: \.isPaused)
    return pausedSoFar.last?.startTime ?? instant
  }

  /// The item on at `instant`, then the item on as each one ends, up to the three Tracking
  /// carries. Stops at the first instant with no item on, so it never skips a gap.
  static private func backToBack<Item: TimeWindow>(from instant: Date, itemAt: (Date) -> Item?) -> [Item] {
    var items: [Item] = []
    var instant = instant
    while items.count < 3, let item = itemAt(instant) {
      items.append(item)
      instant = item.endTime
    }
    return items
  }
}
