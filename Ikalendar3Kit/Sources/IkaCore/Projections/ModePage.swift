//
//  ModePage.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - ModePage

/// What a Mode's watch page shows at an instant: the Mode's screen, whose current item its Now
/// row summarizes, whose next item the page shows under it and whose later items a tap on the
/// page lists. Every Mode of the Mode value has one, by an exhaustive switch.
public enum ModePage: Hashable, Sendable {
  /// A continuous Battle Mode's page.
  case battle(BattleScreen)
  /// Salmon Run's page: its regular Shifts and Big Runs.
  case salmonRun(SalmonRunScreen)

  /// The Mode the page shows.
  public var mode: Mode {
    switch self {
      case .battle(let screen): .battle(screen.mode)
      case .salmonRun: .salmonRun
    }
  }

  /// The page's current item, or why none is, as the Mode's Now row shows it.
  public var summary: ModeSummary {
    switch self {
      case .battle(let screen): .battle(screen.mode, screen.current)
      case .salmonRun(let screen): .salmonRun(screen.current)
    }
  }
}

extension Snapshot {
  /// `mode`'s page at `instant`, or `nil` before the schedules feed's first good response.
  public func modePage(of mode: Mode, at instant: Date) -> ModePage? {
    switch mode {
      case .battle(let battleMode): battleScreen(of: battleMode, at: instant).map(ModePage.battle)
      case .salmonRun: salmonRunScreen(at: instant).map(ModePage.salmonRun)
    }
  }
}
