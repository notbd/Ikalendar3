//
//  WatchWidget.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - WatchWidgetContent

/// What a watch complication or the Smart Stack widget shows for one Mode at an entry's date:
/// its current and next Rotation or Shift, each with its end for the countdown. What each family
/// draws of it is ticket 47's decision.
public enum WatchWidgetContent: Hashable, Sendable {
  /// A Battle Mode's current and next Rotation: Splatfest Battle's while a Splatfest replaces
  /// it, as on every widget set to a Battle Mode.
  case battle(BattleWidgetContent)
  /// Salmon Run's current and next regular Shift or Big Run.
  case salmonRun(SalmonRunWidgetContent)

  /// The Mode the complication is set to.
  public var mode: Mode {
    switch self {
      case .battle(let content): .battle(content.mode)
      case .salmonRun: .salmonRun
    }
  }
}

// MARK: - Building

extension Snapshot {
  /// The timeline from `instant` of a watch complication or Smart Stack widget set to `mode`,
  /// read from the watch's own cache, or `nil` before the schedules feed's first good response.
  /// It has an entry at every boundary of the Mode's published Schedule.
  public func watchWidgetTimeline(of mode: Mode, from instant: Date) -> WidgetTimeline<WatchWidgetContent>? {
    switch mode {
      case .battle(let battleMode):
        battleTimeline(of: battleMode, from: instant, upcomingCount: 1)?.map(WatchWidgetContent.battle)
      case .salmonRun:
        salmonRunTimeline(from: instant, upcomingCount: 1)?.map(WatchWidgetContent.salmonRun)
    }
  }
}
