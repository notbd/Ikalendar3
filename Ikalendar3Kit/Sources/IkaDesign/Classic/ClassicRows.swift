//
//  ClassicRows.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import Foundation
import IkaCore

// MARK: - ClassicBattleRow

/// One section of Classic's Battle Mode list, in ikalendar 2's order: the current Rotation in the
/// featured primary cell under "Now:", or why none is on, then the next Rotation under "Next:"
/// and every later one in a secondary cell under its time range alone.
enum ClassicBattleRow: Hashable, Identifiable {
  /// The Rotation on now, with how far it has run.
  case current(Running<Rotation>)
  /// A Splatfest pauses the Battle Mode until `returnTime`.
  case paused(returnTime: Date)
  /// Nothing is on: the Schedule ran out, or its first Rotation has not started.
  case nothingCurrent
  /// A Rotation still to come; `isNext` for the first of them.
  case upcoming(Rotation, isNext: Bool)

  /// The rows of `screen`.
  static func rows(of screen: BattleScreen) -> [ClassicBattleRow] {
    let upcoming: [ClassicBattleRow] = ([screen.next].compactMap(\.self) + screen.later)
      .enumerated()
      .map { .upcoming($1, isNext: $0 == 0) }

    switch screen.current {
      case .running(let running): return [.current(running)] + upcoming
      case .paused(let returnTime): return [.paused(returnTime: returnTime)] + upcoming
      case .nothingCurrent: return [.nothingCurrent] + upcoming
    }
  }

  /// A Rotation keeps its id from a secondary cell to the primary one, so its row stays and the
  /// matched geometry inside it glides; the status rows share one id.
  var id: ClassicRowID {
    switch self {
      case .current(let running): .rotation(running.item.startTime)
      case .upcoming(let rotation, _): .rotation(rotation.startTime)
      case .paused,
           .nothingCurrent: .status
    }
  }

  /// The tag before the row's header: "Now:" on the featured place, "Next:" on the next Rotation.
  var tag: ClassicText? {
    switch self {
      case .current,
           .paused,
           .nothingCurrent: .now
      case .upcoming(_, let isNext): isNext ? .next : nil
    }
  }
}

// MARK: - ClassicSalmonRunRow

/// One section of Classic's Salmon Run list, in ikalendar 2's order: a running or next Eggstra
/// Work on top, then the Shifts in time order with a Big Run where it falls. The running Shift is open;
/// with none open, the first to come opens soon.
enum ClassicSalmonRunRow: Hashable, Identifiable {
  /// A Shift, with its progress while it runs and its tag.
  case shift(Shift, progress: WindowProgress?, tag: Tag?)
  /// No Shift is on and none is to come.
  case nothingCurrent

  /// The tag before a Shift's header.
  enum Tag: Hashable {
    /// "Open!": the Shift runs.
    case open
    /// "Soon:": no Shift runs and this one comes first, with a countdown to its start.
    case soon
    /// "Next:": the Shift after the open or soon one.
    case next

    /// The tag's text.
    var text: ClassicText {
      switch self {
        case .open: .open
        case .soon: .soon
        case .next: .next
      }
    }
  }

  /// The rows of `screen`.
  static func rows(of screen: SalmonRunScreen) -> [ClassicSalmonRunRow] {
    // A next Eggstra Work goes untagged: its time range says when it starts.
    let eggstraWork: [ClassicSalmonRunRow] =
      if let running = screen.eggstraWork { [.shift(running.item, progress: running.progress, tag: .open)] }
      else if let next = screen.nextEggstraWork { [.shift(next, progress: nil, tag: nil)] }
      else { [] }
    let upcoming: [Shift] = [screen.next].compactMap(\.self) + screen.later

    switch screen.current {
      case .running(let running):
        return eggstraWork
          + [.shift(running.item, progress: running.progress, tag: .open)]
          + upcoming.enumerated().map { .shift($1, progress: nil, tag: $0 == 0 ? .next : nil) }

      case .paused,
           .nothingCurrent:
        guard !upcoming.isEmpty else { return eggstraWork + [.nothingCurrent] }

        let tags: [Tag] = [.soon, .next]
        return eggstraWork
          + upcoming.enumerated().map { .shift($1, progress: nil, tag: $0 < tags.count ? tags[$0] : nil) }
    }
  }

  /// A Shift keeps its id while its tag and progress change; the status row has its own.
  var id: ClassicRowID {
    switch self {
      case .shift(let shift, _, _): .shift(shift)
      case .nothingCurrent: .status
    }
  }

  /// The Shift, or `nil` for the status row.
  var shift: Shift? {
    if case .shift(let shift, _, _) = self { shift } else { nil }
  }

  /// The Shift's tag, or `nil` for an untagged Shift and the status row.
  var tag: Tag? {
    if case .shift(_, _, let tag) = self { tag } else { nil }
  }
}

// MARK: - ClassicRowID

/// What keeps a row's identity in a Classic list while the clock runs.
enum ClassicRowID: Hashable {
  /// A Rotation, by its start: Battle Modes never hold two Rotations at one start.
  case rotation(Date)
  /// A Shift. An Eggstra Work can start with a regular Shift, so the start alone is not enough.
  case shift(Shift)
  /// The row saying why nothing is on.
  case status
}
#endif
