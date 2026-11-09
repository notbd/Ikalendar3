//
//  WatchRefreshSchedule.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - WatchRefreshSchedule

/// When the watch asks for its next background refresh: about every two hours, five minutes past a
/// Rotation boundary, once splatoon3.ink serves the Schedule with the Rotation the boundary added.
///
/// watchOS grants about four background runs an hour while one of the app's complications is on
/// the active face, and fewer otherwise; each run asks for the next, so the chain spends one
/// run every two hours. Complication timelines hold an entry at every boundary of the cached
/// Schedule, so no run is needed for the switch itself.
public enum WatchRefreshSchedule {
  /// The run to ask for after a refresh at `instant`, or after a move to the background at
  /// `instant`: the first Rotation boundary plus the settle delay that is at least the gate's hour
  /// after `instant`. An earlier run would find every feed's gate still closed.
  static public func nextRun(after instant: Date) -> Date {
    let earliest: TimeInterval = instant.timeIntervalSince1970 + FeedGate.interval / .seconds(1)
    let boundaries: Double = ((earliest - settleDelay) / rotationLength).rounded(.up)
    return Date(timeIntervalSince1970: boundaries * rotationLength + settleDelay)
  }

  /// A Battle Rotation's length. Rotations change at even UTC hours, and the Unix epoch is one.
  static let rotationLength: TimeInterval = 2 * 3600

  /// How long after a boundary a run waits: splatoon3.ink's updater runs every minute from the
  /// hour to five past it, and a probe found the new Schedule live 37 seconds after a boundary.
  static let settleDelay: TimeInterval = 5 * 60
}
