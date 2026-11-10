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
    entries(current: current, upcoming: upcoming, as: \.self)
  }

  /// The current entry for `current`, then one per item still to come, each source item made
  /// the axis's `item`.
  static private func entries<Source>(
    current: OnNow<Source>,
    upcoming: [Source],
    as item: (Source) -> Item)
    -> [TimelineEntry]
  {
    let first: TimelineEntry =
      switch current {
        case .running(let running): .item(item(running.item), progress: running.progress)
        case .paused(let returnTime): .paused(returnTime: returnTime)
        case .nothingCurrent: .nothingCurrent
      }
    return [first] + upcoming.map { .item(item($0), progress: nil) }
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

extension TimelineEntry<ChallengeWindow> {
  /// The axis of one Challenge: all its windows, past ones included, the current one with its
  /// progress.
  static func entries(of listing: ChallengeScreen.Listing) -> [TimelineEntry] {
    listing.windows.map { marked in
      let window: ChallengeWindow = .init(challenge: listing.challenge, window: marked.window)
      return if case .current(let progress) = marked.mark { .item(window, progress: progress) }
      else { .item(window, progress: nil) }
    }
  }
}

extension TimelineEntry<TimelineSplatfestItem> {
  /// The axis of the Splatfest screen: Tricolor Turf War on top in the second half, then the
  /// form's current Rotation or nothing current, its next and later Rotations, and Regular
  /// Battle's Rotations from the Splatfest's end.
  static func entries(of screen: SplatfestScreen) -> [TimelineEntry] {
    let tricolorTurfWar: [TimelineEntry] = screen.tricolorTurfWar
      .map { [.item(.tricolorTurfWar($0.item), progress: $0.progress)] } ?? []
    let upcoming: [Rotation] = [screen.next].compactMap(\.self) + screen.later + screen.afterwards
    return tricolorTurfWar + entries(current: screen.current, upcoming: upcoming, as: TimelineSplatfestItem.rotation)
  }
}

// MARK: - TimelineSplatfestItem

/// What the Splatfest screen's axis holds: Rotations, of the form and of Regular Battle after
/// the end, and Tricolor Turf War.
enum TimelineSplatfestItem: TimeWindow, Hashable {
  case rotation(Rotation)
  case tricolorTurfWar(TricolorTurfWar)

  var startTime: Date {
    switch self {
      case .rotation(let rotation): rotation.startTime
      case .tricolorTurfWar(let tricolorTurfWar): tricolorTurfWar.startTime
    }
  }

  var endTime: Date {
    switch self {
      case .rotation(let rotation): rotation.endTime
      case .tricolorTurfWar(let tricolorTurfWar): tricolorTurfWar.endTime
    }
  }
}
#endif
