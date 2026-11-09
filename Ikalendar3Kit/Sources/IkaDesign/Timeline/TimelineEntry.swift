//
//  TimelineEntry.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import Foundation
import IkaCore

// MARK: - TimelineEntry

/// One place on Timeline's time axis, which reads top to bottom in one column: a Rotation or
/// Shift hung on its start time, or why none is on now.
enum TimelineEntry<Item: TimeWindow & Hashable & Sendable>: Hashable, Identifiable {
  /// A Rotation or Shift, with how far it has run while it runs: the axis fills that share.
  case item(Item, progress: WindowProgress?)
  /// A Splatfest pauses the Battle Mode until `returnTime`.
  case paused(returnTime: Date)
  /// Nothing is on: the Schedule ran out, or its first item has not started.
  case nothingCurrent

  /// An item keeps its id when it becomes current, so its slot stays and the axis moves on; the
  /// status entries share one id.
  var id: Identity {
    switch self {
      case .item(let item, _): .item(item)
      case .paused,
           .nothingCurrent: .status
    }
  }

  /// The Rotation or Shift, or `nil` for a status entry.
  var item: Item? {
    if case .item(let item, _) = self { item } else { nil }
  }

  /// How far the item has run, or `nil` unless it runs now.
  var progress: WindowProgress? {
    if case .item(_, let progress) = self { progress } else { nil }
  }

  /// The current entry for `current`, then one per item still to come.
  static private func entries(current: OnNow<Item>, upcoming: [Item]) -> [TimelineEntry] {
    let first: TimelineEntry =
      switch current {
        case .running(let running): .item(running.item, progress: running.progress)
        case .paused(let returnTime): .paused(returnTime: returnTime)
        case .nothingCurrent: .nothingCurrent
      }
    return [first] + upcoming.map { .item($0, progress: nil) }
  }
}

// MARK: TimelineEntry.Identity

extension TimelineEntry {
  /// What keeps an entry's identity while the clock runs.
  enum Identity: Hashable {
    /// A Rotation or Shift, by value: an Eggstra Work can start with a regular Shift, so a start
    /// time alone is not enough.
    case item(Item)
    /// The entry saying why nothing is on.
    case status
  }
}

extension TimelineEntry<Rotation> {
  /// The axis of a Battle Mode's screen: the current Rotation, its pause or nothing current, then
  /// the next and every later Rotation.
  static func entries(of screen: BattleScreen) -> [TimelineEntry] {
    entries(current: screen.current, upcoming: [screen.next].compactMap(\.self) + screen.later)
  }
}

extension TimelineEntry<Shift> {
  /// The axis of the Salmon Run screen: the running or announced Eggstra Work on top, then the
  /// current Shift or nothing current, then the next and every later Shift, with a Big Run where
  /// it falls.
  static func entries(of screen: SalmonRunScreen) -> [TimelineEntry] {
    let eggstraWork: [TimelineEntry] =
      if let running = screen.eggstraWork { [.item(running.item, progress: running.progress)] }
      else if let next = screen.nextEggstraWork { [.item(next, progress: nil)] }
      else { [] }
    return eggstraWork + entries(current: screen.current, upcoming: [screen.next].compactMap(\.self) + screen.later)
  }
}
#endif
