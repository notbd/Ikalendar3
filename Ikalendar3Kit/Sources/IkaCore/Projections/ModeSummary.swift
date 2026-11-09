//
//  ModeSummary.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - ModeSummary

/// One Mode at a glance: its current Rotation or Shift with the time left and the share passed,
/// or why none is. Every Surface that lists Modes reads it, such as the iPad sidebar, the Mac
/// Overview and menu bar window, the Series and Open (or Open and Pro) menu and the watch's pages.
///
/// It is the current item of the Mode's screen, so the two always agree. While a Splatfest
/// pauses a Battle Mode, its summary reports the pause with the time the Battle Mode returns, as
/// the iPhone tabs do. Splatfest Battle never stands in for it: only widgets substitute.
public enum ModeSummary: Hashable, Sendable {
  /// A continuous Battle Mode's current Rotation, its pause by a Splatfest, or nothing current.
  case battle(BattleMode, OnNow<Rotation>)
  /// A form of Splatfest Battle's current Rotation, or nothing current, while its Splatfest is
  /// announced or runs.
  case splatfestBattle(SplatfestBattleForm, OnNow<Rotation>)
  /// Salmon Run's current regular Shift or Big Run, never an Eggstra Work, or nothing current.
  case salmonRun(OnNow<Shift>)

  /// The Mode summarized, or `nil` for a form of Splatfest Battle, which is no `Mode`: no widget,
  /// control, Siri or Tracking chooses it.
  public var mode: Mode? {
    switch self {
      case .battle(let mode, _): .battle(mode)
      case .splatfestBattle: nil
      case .salmonRun: .salmonRun
    }
  }

  /// The current Rotation's or Shift's time left and share passed, or `nil` while none is on.
  public var progress: WindowProgress? {
    switch self {
      case .battle(_, .running(let running)),
           .splatfestBattle(_, .running(let running)): running.progress
      case .salmonRun(.running(let running)): running.progress
      case .battle,
           .splatfestBattle,
           .salmonRun: nil
    }
  }
}

extension Snapshot {
  /// `mode`'s summary at `instant`, or `nil` before the schedules feed's first good response:
  /// the current item of its page, so a Now row and the page it opens always agree.
  public func summary(of mode: Mode, at instant: Date) -> ModeSummary? {
    modePage(of: mode, at: instant)?.summary
  }

  /// The summaries of the Mode value's five Modes at `instant`, in its order: the four continuous
  /// Battle Modes, then Salmon Run. The Surfaces that list every Mode read it: the Mac menu bar
  /// window and Overview and the watch's Now page. A Battle Mode a Splatfest pauses stays listed
  /// with its pause; Splatfest Battle never stands in for it. `nil` before the schedules feed's
  /// first good response.
  public func summaries(at instant: Date) -> [ModeSummary]? {
    guard schedules != nil else { return nil }

    return Mode.allCases.compactMap { summary(of: $0, at: instant) }
  }

  /// The summary of `form` of Splatfest Battle at `instant`: the current item of its Splatfest
  /// screen, or `nil` whenever there is no Splatfest screen.
  public func summary(of form: SplatfestBattleForm, at instant: Date) -> ModeSummary? {
    splatfestScreen(of: form, at: instant).map { .splatfestBattle(form, $0.current) }
  }
}
