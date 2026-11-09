//
//  BattleScreen.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - BattleScreen

/// What a continuous Battle Mode's screen shows at an instant: the current Rotation, or why none
/// is, the next Rotation and every later one in the published Schedule. It holds ids and times
/// only; names and images resolve at display time.
public struct BattleScreen: Hashable, Sendable {
  /// The Battle Mode.
  public let mode: BattleMode
  /// The Rotation on now with how far it has run, the pause by a Splatfest, or nothing current.
  public let current: OnNow<Rotation>
  /// The first Rotation after the current one, or after the instant when none is current.
  public let next: Rotation?
  /// Every published Rotation after `next`, in time order.
  public let later: [Rotation]
  /// When the schedules feed shown was last confirmed.
  public let fetchTime: Date
}

extension Snapshot {
  /// `mode`'s screen at `instant`, or `nil` before the schedules feed's first good response.
  /// A Schedule that failed to decode is empty, so it shows nothing current.
  public func battleScreen(of mode: BattleMode, at instant: Date) -> BattleScreen? {
    guard let schedules else { return nil }

    let lineup = schedules.content.battleLineup(of: .battle(mode), at: instant)
    return BattleScreen(
      mode: mode,
      current: OnNow(lineup.current, at: instant),
      next: lineup.next,
      later: lineup.later,
      fetchTime: schedules.fetchTime)
  }
}
