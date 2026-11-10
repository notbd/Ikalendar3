//
//  TrackingReminder.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - TrackingReminder

/// What a Tracking view says once its Rotation or Shift has ended with no update, instead of a
/// frozen countdown beside an old item. The raw value is the catalog key.
public enum TrackingReminder: String, CaseIterable, Hashable, Sendable {
  /// The view moved to the next item on its own, and the switch after it needs a Refresh.
  case nextSwitchNeedsRefresh = "reminder.nextSwitchNeedsRefresh"
  /// The view is past a boundary no update covered: the schedule is out of date until a Refresh.
  case scheduleOutOfDate = "reminder.scheduleOutOfDate"

  /// The reminder in a text set.
  public func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, in: language)
  }
}
