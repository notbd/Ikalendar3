//
//  SplatfestScreen.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - SplatfestScreen

/// What the Splatfest screen shows at an instant, in one form of Splatfest Battle: the Splatfest
/// card, the form's current Rotation, or why none is, its next and later Rotations, Tricolor Turf
/// War in the second half, then the Rotations that follow once the Splatfest ends. It holds ids,
/// times and the stored art; the title and team names resolve at display time from the
/// Splatfest's id.
public struct SplatfestScreen: Hashable, Sendable {
  /// The Splatfest the card shows: its times and team colours.
  public let splatfest: Splatfest
  /// The card's art, a local image file the refresh engine stored, or `nil` while none is
  /// stored: the card then shows the team colours.
  public let art: URL?
  /// Where the Splatfest stands: announced, first half or second half.
  public let phase: Splatfest.Phase
  /// The form of Splatfest Battle shown, the app's Open or Pro choice.
  public let form: SplatfestBattleForm
  /// The form's Rotation on now with how far it has run, or nothing current: before the start,
  /// or past its last published Rotation.
  public let current: OnNow<Rotation>
  /// The form's first Rotation after the current one, or after the instant when none is current.
  public let next: Rotation?
  /// The form's published Rotations after `next`, in time order.
  public let later: [Rotation]
  /// Tricolor Turf War with how far it has run, in the second half only.
  public let tricolorTurfWar: Running<TricolorTurfWar>?
  /// Regular Battle's published Rotations from the Splatfest's end, in time order: what the tab
  /// shows once it turns back into Regular Battle's.
  public let afterwards: [Rotation]
  /// When the schedules feed shown was last confirmed.
  public let fetchTime: Date
}

// MARK: - TricolorTurfWar

/// A Splatfest's Tricolor Turf War: on its Stages from the midterm time to the end.
public struct TricolorTurfWar: TimeWindow, Hashable, Sendable {
  /// The Stages, in the feed's order.
  public let stages: [StageID]
  /// The Splatfest's midterm time.
  public let startTime: Date
  /// The Splatfest's end.
  public let endTime: Date
}

extension Splatfest {
  /// The Splatfest's Tricolor Turf War.
  public var tricolorTurfWar: TricolorTurfWar {
    TricolorTurfWar(stages: tricolorStages, startTime: midtermTime, endTime: endTime)
  }
}

extension Snapshot {
  /// The Splatfest screen in `form` at `instant`, or `nil` before the schedules feed's first good
  /// response and when it names no Splatfest that is announced or running.
  public func splatfestScreen(of form: SplatfestBattleForm, at instant: Date) -> SplatfestScreen? {
    guard let schedules, let splatfest else { return nil }

    let phase = splatfest.phase(at: instant)
    guard phase != .over else { return nil }

    let feed = schedules.content
    let lineup = feed.battleLineup(of: .splatfestBattle(form), at: instant)
    let tricolorTurfWar = splatfest.tricolorTurfWar
    return SplatfestScreen(
      splatfest: splatfest,
      art: splatfestArt,
      phase: phase,
      form: form,
      current: OnNow(lineup.current, at: instant),
      next: lineup.next,
      later: lineup.later,
      tricolorTurfWar: phase == .secondHalf
        ? Running(item: tricolorTurfWar, progress: tricolorTurfWar.progress(at: instant))
        : nil,
      afterwards: feed.rotations(for: .battle(.regular)).filter { !$0.isPaused && splatfest.endTime <= $0.startTime },
      fetchTime: schedules.fetchTime)
  }
}
