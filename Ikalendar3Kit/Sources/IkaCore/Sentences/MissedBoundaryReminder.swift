//
//  MissedBoundaryReminder.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - MissedBoundaryReminder

/// What a Live Activity says once its Rotation or Shift has ended with no update, instead of a
/// frozen countdown beside an old item. The raw value is the catalog key.
public enum MissedBoundaryReminder: String, CaseIterable, Sendable {
  /// The first level: the activity shows the next item, and the switch after it needs a Refresh.
  case nextSwitchNeedsRefresh = "reminder.nextSwitchNeedsRefresh"
  /// The second level: the activity has nothing current to show.
  case outOfDate = "reminder.outOfDate"

  /// The reminder in a text set.
  public func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, in: language)
  }
}
