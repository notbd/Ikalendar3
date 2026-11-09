//
//  SalmonRunScreen.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - SalmonRunScreen

/// What the Salmon Run screen shows at an instant: a running Eggstra Work on top, then the
/// current Shift, or why none is, the next Shift and every later one, with a Big Run among them
/// where it falls. Each Shift carries its kind, Stage, four weapons, King Salmonid and times, as
/// ids and times only; names and images resolve at display time.
public struct SalmonRunScreen: Hashable, Sendable {
  /// The Eggstra Work running at the instant, apart from the Shifts: it is never Salmon Run's
  /// current or next Shift.
  public let eggstraWork: Running<Shift>?
  /// The regular Shift or Big Run on now with how far it has run, or nothing current.
  public let current: OnNow<Shift>
  /// The first Shift after the current one, or after the instant when none is current.
  public let next: Shift?
  /// Every published Shift after `next`, in time order.
  public let later: [Shift]
  /// When the schedules feed shown was last confirmed.
  public let fetchTime: Date
}

extension Snapshot {
  /// The Salmon Run screen at `instant`, or `nil` before the schedules feed's first good
  /// response. A Schedule that failed to decode is empty and leaves the other intact: failed
  /// Shifts show nothing current, failed Eggstra Works show none on top.
  public func salmonRunScreen(at instant: Date) -> SalmonRunScreen? {
    guard let schedules else { return nil }

    let lineup = schedules.content.salmonRunLineup(at: instant)
    let eggstraWork = schedules.content.eggstraWorkLineup(at: instant).current.item
    return SalmonRunScreen(
      eggstraWork: eggstraWork.map { Running(item: $0, progress: $0.progress(at: instant)) },
      current: OnNow(lineup.current, at: instant),
      next: lineup.next,
      later: lineup.later,
      fetchTime: schedules.fetchTime)
  }
}
