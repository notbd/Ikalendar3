//
//  Snapshot+Feed.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension Snapshot {
  /// When a feed's content was last confirmed, or `nil` while the snapshot has none.
  func fetchTime(of feed: Feed) -> Date? {
    switch feed {
      case .schedules: schedules?.fetchTime
      case .festivals: festivals?.fetchTime
      case .locale(let language): locales[language]?.fetchTime
    }
  }

  /// Marks a feed's content stale, if the snapshot has any.
  mutating func markStale(_ feed: Feed) {
    switch feed {
      case .schedules: schedules?.isStale = true
      case .festivals: festivals?.isStale = true
      case .locale(let language): locales[language]?.isStale = true
    }
  }
}
