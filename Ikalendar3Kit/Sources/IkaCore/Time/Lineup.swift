//
//  Lineup.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Lineup

/// What one Schedule holds at one instant: the item on now (or why none is), the item that comes
/// next and every item after it.
public struct Lineup<Item: TimeWindow & Hashable & Sendable>: Hashable, Sendable {
  /// The item on at the instant, or why none is.
  public let current: Current
  /// The first published item that starts at or after the current one ends, or after the instant
  /// when nothing is current.
  public let next: Item?
  /// Every published item after `next`, in time order.
  public let later: [Item]
}

// MARK: Lineup.Current

extension Lineup {
  /// What is on at the instant.
  public enum Current: Hashable, Sendable {
    /// An item is on.
    case item(Item)
    /// Nothing is on and a later item is published: between two Challenge windows, or before
    /// the first published item.
    case gap
    /// A Splatfest pauses the Battle Mode, which returns at `returnTime`.
    case paused(returnTime: Date)
    /// A continuous Schedule is past its last published item: its data ran out.
    case ranOut
    /// An event Schedule (Challenges, Eggstra Work) is past its last published item: no later
    /// one is announced yet.
    case noneAnnounced

    /// The item on, or `nil` when none is.
    public var item: Item? {
      if case .item(let item) = self { item } else { nil }
    }
  }
}

// MARK: Building

extension Lineup {
  /// The lineup of time-ordered `items` at `instant`, reporting `pastLast` (`.ranOut` or
  /// `.noneAnnounced`) once the last item has ended.
  init(_ items: [Item], at instant: Date, pastLast: Current) {
    if let current = items.first(where: { $0.isRunning(at: instant) }) {
      self.init(current: .item(current), upcoming: items.filter { current.endTime <= $0.startTime })
    }
    else if items.contains(where: { instant < $0.startTime }) {
      self.init(current: .gap, upcoming: items.filter { instant < $0.startTime })
    }
    else {
      self.init(current: pastLast, upcoming: [])
    }
  }

  /// A lineup whose next and later items are `upcoming`, in time order.
  init(current: Current, upcoming: [Item]) {
    self.init(current: current, next: upcoming.first, later: Array(upcoming.dropFirst()))
  }
}
