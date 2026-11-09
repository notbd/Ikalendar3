//
//  InkPanelEntry.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - InkPanelEntry

/// One panel of an Ink list: a Rotation or Shift with its place, which decides whether the panel
/// is featured (taped, with progress) and which state tag it wears.
struct InkPanelEntry<Item: TimeWindow & Hashable & Sendable>: Hashable, Identifiable {
  /// The Rotation or Shift.
  let item: Item
  /// Where it stands.
  let place: Place

  /// The panel's identity: the item's start, which stays when the item moves from Next into
  /// Now, so its panel glides into the featured place instead of being replaced.
  var id: Date { item.startTime }

  /// The panels of a list: the running item, then the next, then every later one.
  static func entries(current: OnNow<Item>, next: Item?, later: [Item]) -> [Self] {
    var entries: [Self] = []
    if case .running(let running) = current {
      entries.append(.init(item: running.item, place: .now(running.progress)))
    }
    if let next {
      entries.append(.init(item: next, place: .next))
    }
    return entries + later.map { .init(item: $0, place: .later) }
  }
}

// MARK: InkPanelEntry.Place

extension InkPanelEntry {
  /// Where a panel's item stands.
  enum Place: Hashable {
    /// On now, with how far it has run: the featured panel, tagged "Now!".
    case now(WindowProgress)
    /// The first after the current one, tagged "Next".
    case next
    /// After the next one, untagged.
    case later
  }
}
