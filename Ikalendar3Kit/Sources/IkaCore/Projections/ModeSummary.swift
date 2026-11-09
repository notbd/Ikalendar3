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
  /// `mode`'s summary at `instant`, or `nil` before the schedules feed's first good response.
  public func summary(of mode: Mode, at instant: Date) -> ModeSummary? {
    switch mode {
      case .battle(let battleMode): battleScreen(of: battleMode, at: instant).map { .battle(battleMode, $0.current) }
      case .salmonRun: salmonRunScreen(at: instant).map { .salmonRun($0.current) }
    }
  }

  /// The summary of `form` of Splatfest Battle at `instant`: the current item of its Splatfest
  /// screen, or `nil` whenever there is no Splatfest screen.
  public func summary(of form: SplatfestBattleForm, at instant: Date) -> ModeSummary? {
    splatfestScreen(of: form, at: instant).map { .splatfestBattle(form, $0.current) }
  }
}
