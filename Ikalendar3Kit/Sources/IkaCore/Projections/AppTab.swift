//
//  AppTab.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - AppTab

/// One tab of the iPhone tab bar: a Mode tab, or the Splatfest tab, which takes Regular Battle's
/// place while a Splatfest runs.
///
/// The Anarchy tab's Series or Open choice and the Splatfest tab's Open or Pro choice are the
/// app's state, not part of the tab, so switching forms never changes which tab is selected.
public enum AppTab: CaseIterable, Hashable, Sendable {
  /// One of the five Mode tabs.
  case mode(ModeTab)
  /// The Splatfest tab.
  case splatfest

  /// The five Mode tabs, then the Splatfest tab.
  static public var allCases: [AppTab] { ModeTab.allCases.map(AppTab.mode) + [.splatfest] }

  /// The place the tab takes in the tab bar: its own Mode tab's, or Regular Battle's for the
  /// Splatfest tab. A stable selection value across a Splatfest's start and end, and the default
  /// Mode value that opens on the tab.
  public var place: ModeTab {
    switch self {
      case .mode(let tab): tab
      case .splatfest: .regularBattle
    }
  }

  /// What a second tap on the tab does while it is selected.
  public var repeatedSelectionAction: RepeatedSelectionAction {
    switch self {
      case .mode(.anarchy): .openMenu(.anarchy)
      case .splatfest: .openMenu(.splatfestBattle)
      case .mode(.regularBattle),
           .mode(.xBattle),
           .mode(.challenge),
           .mode(.salmonRun): .scrollToTop
    }
  }
}

// MARK: - RepeatedSelectionAction

/// What a second tap on the selected tab does.
public enum RepeatedSelectionAction: Hashable, Sendable {
  /// Scrolls the tab's list to the top.
  case scrollToTop
  /// Opens the tab's menu instead: the status bar still scrolls to the top.
  case openMenu(TabMenu)
}

// MARK: - TabMenu

/// The choice a tab's menu offers above the selected tab.
public enum TabMenu: Hashable, Sendable {
  /// Anarchy Series or Anarchy Open, on the Anarchy tab.
  case anarchy
  /// Splatfest Battle (Open) or (Pro), on the Splatfest tab.
  case splatfestBattle

  /// The two Battle Modes the menu offers, in menu order. The first is the tab's Mode until the
  /// player picks the other.
  public var modes: [RotationMode] {
    switch self {
      case .anarchy: [.battle(.anarchySeries), .battle(.anarchyOpen)]
      case .splatfestBattle: SplatfestBattleForm.allCases.map(RotationMode.splatfestBattle)
    }
  }
}

// MARK: - TabMenuOption

/// One option of a tab's menu: a Battle Mode and its Mode summary. Only `Snapshot.options(of:at:)`
/// makes one, so an option always holds one of its menu's modes.
public struct TabMenuOption: Hashable, Sendable {
  /// The Battle Mode the option switches the tab to.
  public let mode: RotationMode
  /// The Mode's summary, or `nil` when it has no screen: before the schedules feed's first good
  /// response, or for a form of Splatfest Battle outside a Splatfest.
  public let summary: ModeSummary?
}

extension Snapshot {
  /// `menu`'s options at `instant`, in menu order. Each one's summary is the current item of its
  /// Mode's screen, so the menu and the screen behind it always agree.
  public func options(of menu: TabMenu, at instant: Date) -> [TabMenuOption] {
    menu.modes.map { mode in
      let summary: ModeSummary? =
        switch mode {
          case .battle(let battleMode): summary(of: Mode.battle(battleMode), at: instant)
          case .splatfestBattle(let form): summary(of: form, at: instant)
        }
      return TabMenuOption(mode: mode, summary: summary)
    }
  }
}

// MARK: - Tab set

extension Snapshot {
  /// The iPhone's tabs at `instant`, in tab bar order: Regular Battle, Anarchy, X Battle,
  /// Challenge and Salmon Run, with the Splatfest tab first in Regular Battle's place while a
  /// Splatfest runs, its first and second half alike.
  public func tabs(at instant: Date) -> [AppTab] {
    ModeTab.allCases.map { tab(in: $0, at: instant) }
  }

  /// The tab in `place` at `instant`.
  public func tab(in place: ModeTab, at instant: Date) -> AppTab {
    let isSplatfestPlace = place == AppTab.splatfest.place && splatfest?.isRunning(at: instant) == true
    return isSplatfestPlace ? .splatfest : .mode(place)
  }
}
