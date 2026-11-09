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
/// Overview and menu bar window, the Series and Open menu and the watch's pages.
///
/// It is the current item of the Mode's screen, so the two always agree. While a Splatfest
/// pauses a Battle Mode, its summary reports the pause with the time the Battle Mode returns, as
/// the iPhone tabs do. Splatfest Battle never stands in for it: only widgets substitute.
public enum ModeSummary: Hashable, Sendable {
  /// A continuous Battle Mode's current Rotation, its pause by a Splatfest, or nothing current.
  case battle(BattleMode, OnNow<Rotation>)
  /// Salmon Run's current regular Shift or Big Run, never an Eggstra Work, or nothing current.
  case salmonRun(OnNow<Shift>)

  /// The Mode summarized.
  public var mode: Mode {
    switch self {
      case .battle(let mode, _): .battle(mode)
      case .salmonRun: .salmonRun
    }
  }
}

extension Snapshot {
  /// `mode`'s summary at `instant`, or `nil` before the schedules feed's first good response:
  /// the current item of its page, so a Now row and the page it opens always agree.
  public func summary(of mode: Mode, at instant: Date) -> ModeSummary? {
    modePage(of: mode, at: instant)?.summary
  }
}
