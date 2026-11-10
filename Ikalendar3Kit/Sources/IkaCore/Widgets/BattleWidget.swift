//
//  BattleWidget.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - BattleWidgetFamily

/// A family of the widget set to one Battle Mode: the Home Screen sizes and the Lock Screen
/// families. The extra large widget lists every Battle Mode and has its own timeline
/// (`Snapshot.extraLargeBattleWidgetTimeline(from:)`).
public enum BattleWidgetFamily: CaseIterable, Hashable, Sendable {
  /// The current Rule, Stages and the end time the countdown runs to.
  case small
  /// The small widget's content and the next Rotation.
  case medium
  /// The medium widget's content and the three Rotations after the next.
  case large
  /// Lock Screen, circular: the Battle Mode's icon and the countdown.
  case circular
  /// Lock Screen, rectangular: the Battle Mode, the Rule and the time left.
  case rectangular
  /// Lock Screen, inline: the Rule and the time left.
  case inline

  /// How many Rotations after the current one the family shows.
  var upcomingCount: Int {
    switch self {
      case .small,
           .circular,
           .rectangular,
           .inline: 0
      case .medium: 1
      case .large: 4
    }
  }
}

// MARK: - BattleWidgetContent

/// What a widget shows for one Battle Mode at an entry's date: the widget set to it, or its row
/// in the extra large widget. IDs and times only; names and images resolve at display time.
public struct BattleWidgetContent: Hashable, Sendable {
  /// The Battle Mode the widget is set to, or the row's.
  public let mode: BattleMode
  /// The Rotation on from the entry's date, or why none is. Its end is where the countdown runs
  /// to. In a widget set to the Battle Mode it is Splatfest Battle's while a Splatfest replaces
  /// it (`shownMode`); a row of the extra large widget shows the Battle Mode paused instead.
  public let current: WidgetCurrent<Rotation>
  /// The Rotations after the current one the family shows, in time order: none, the next, or the
  /// next and the three after it. Fewer when fewer are published.
  public let upcoming: [Rotation]

  /// The Battle Mode the widget names and whose icon it shows: Splatfest Battle's form while it
  /// replaces `mode`, else `mode`.
  public var shownMode: RotationMode {
    current.item?.mode ?? .battle(mode)
  }
}

// MARK: - Splatfest replacement

extension BattleMode {
  /// The form of Splatfest Battle a widget set to this Battle Mode shows while a Splatfest
  /// replaces it: Open, which friends can join together, for Regular Battle and Anarchy Open;
  /// Pro, the ranked form, for Anarchy Series and X Battle. Only widgets substitute; every other
  /// Surface shows the Battle Mode paused.
  public var splatfestForm: SplatfestBattleForm {
    switch self {
      case .regular,
           .anarchyOpen: .open
      case .anarchySeries,
           .x: .pro
    }
  }
}

extension ScheduleFeed {
  /// What a widget set to `mode` holds at `instant`: the Battle Mode's lineup with its paused
  /// windows replaced by its Splatfest Battle form's Rotations, so next and later run on into
  /// the Battle Mode's own Rotations once it returns. With no Splatfest Battle Rotation on during
  /// a pause (they failed to decode, or ran out), the Battle Mode shows paused.
  func widgetLineup(of mode: BattleMode, at instant: Date) -> Lineup<Rotation> {
    let lineup: Lineup = .init(widgetRotations(of: mode), at: instant, pastLast: .ranOut)
    guard
      lineup.current.item == nil,
      case .paused(let returnTime) = battleLineup(of: .battle(mode), at: instant).current
    else { return lineup }

    return Lineup(current: .paused(returnTime: returnTime), next: lineup.next, later: lineup.later)
  }

  /// The Rotations a widget set to `mode` shows, in time order: the Battle Mode's played ones and
  /// its Splatfest Battle form's, which run only in its paused windows.
  private func widgetRotations(of mode: BattleMode) -> [Rotation] {
    (rotations(for: .battle(mode)).filter { !$0.isPaused } + rotations(for: .splatfestBattle(mode.splatfestForm)))
      .sorted { $0.startTime < $1.startTime }
  }

  /// Every instant a Battle Mode's row in the extra large widget may change: the edges of its
  /// windows, paused ones included, and of the Splatfest.
  func boundaries(of mode: BattleMode) -> [Date] {
    edges(of: rotations(for: .battle(mode)) + [currentSplatfest?.splatfest].compactMap(\.self))
  }

  /// Every instant a widget set to `mode` may change: the edges of the Battle Mode's windows,
  /// paused ones included, of its Splatfest Battle form's Rotations and of the Splatfest.
  func widgetBoundaries(of mode: BattleMode) -> [Date] {
    boundaries(of: mode) + edges(of: rotations(for: .splatfestBattle(mode.splatfestForm)))
  }

  /// The starts and ends of `windows`.
  private func edges(of windows: [any TimeWindow]) -> [Date] {
    windows.flatMap { [$0.startTime, $0.endTime] }
  }
}

// MARK: - Building

extension Snapshot {
  /// The timeline from `instant` of `family` set to `mode`, or `nil` before the schedules feed's
  /// first good response. It has an entry at every boundary of the published Schedule, about a
  /// day, and ends with nothing current once that Schedule runs out.
  public func battleWidgetTimeline(
    of mode: BattleMode,
    family: BattleWidgetFamily,
    from instant: Date)
    -> WidgetTimeline<BattleWidgetContent>?
  {
    battleTimeline(of: mode, from: instant, upcomingCount: family.upcomingCount)
  }

  /// The timeline from `instant` of a widget set to `mode` with `upcomingCount` Rotations after
  /// the current one.
  func battleTimeline(
    of mode: BattleMode,
    from instant: Date,
    upcomingCount: Int)
    -> WidgetTimeline<BattleWidgetContent>?
  {
    guard let schedules else { return nil }

    let feed = schedules.content
    return WidgetTimeline(
      from: instant,
      fetchTime: schedules.fetchTime,
      boundaries: feed.widgetBoundaries(of: mode))
    { date in
      let lineup = feed.widgetLineup(of: mode, at: date)
      return BattleWidgetContent(
        mode: mode,
        current: WidgetCurrent(lineup.current),
        upcoming: lineup.upcomingItems(upcomingCount))
    }
  }

  /// The extra large widget's timeline from `instant`, or `nil` before the schedules feed's first
  /// good response. Each entry holds a row for each continuous Battle Mode, in `BattleMode`'s
  /// order, with its current Rotation and no later one.
  ///
  /// It is set to no Battle Mode, so no Splatfest replaces one: while a Splatfest runs, each row
  /// shows its Battle Mode paused until it returns, as the Battle Mode's summary does on every
  /// Surface that lists every Mode.
  public func extraLargeBattleWidgetTimeline(from instant: Date) -> WidgetTimeline<[BattleWidgetContent]>? {
    guard let schedules else { return nil }

    let feed = schedules.content
    return WidgetTimeline(
      from: instant,
      fetchTime: schedules.fetchTime,
      boundaries: BattleMode.allCases.flatMap(feed.boundaries(of:)))
    { date in
      BattleMode.allCases.map { mode in
        BattleWidgetContent(
          mode: mode,
          current: WidgetCurrent(feed.battleLineup(of: .battle(mode), at: date).current),
          upcoming: [])
      }
    }
  }
}
