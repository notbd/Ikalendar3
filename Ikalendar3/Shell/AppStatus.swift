//
//  AppStatus.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Observation

// MARK: - AppStatus

/// The app's in-session state, which no preference keeps.
@Observable
final class AppStatus {
  /// The place of the selected tab. A place, not a tab, so the selection holds while the
  /// Splatfest tab takes Regular Battle's place and when it gives it back.
  private(set) var selectedPlace: ModeTab
  /// The menu shown above the selected tab, if any.
  private(set) var presentedMenu: TabMenu?
  /// The Anarchy tab's Battle Mode: Anarchy Series or Anarchy Open.
  private(set) var anarchyMode: BattleMode = .anarchySeries
  /// The Splatfest tab's form of Splatfest Battle.
  private(set) var splatfestForm: SplatfestBattleForm = .open
  /// Whether Settings is shown on iPhone and iPad.
  var isSettingsPresented = false
  /// The haptic the last refresh run ended with, which the tabs play; `nil` before the first.
  var refreshHaptic: RefreshHaptic?

  /// A status that opens on `selectedPlace`: the default Mode.
  init(selectedPlace: ModeTab) {
    self.selectedPlace = selectedPlace
  }

  /// Handles a tap on `tab` in the tab bar. Another tab is selected and closes the menu; a second
  /// tap on the selected tab follows ticket 08's repeated-selection rule: it opens or closes the
  /// tab's menu, or leaves the system to scroll the list to the top.
  func select(_ tab: AppTab) {
    guard tab.place == selectedPlace else {
      selectedPlace = tab.place
      presentedMenu = nil
      return
    }

    if case .openMenu(let menu) = tab.repeatedSelectionAction {
      presentedMenu = presentedMenu == nil ? menu : nil
    }
  }

  /// Closes the menu with no change.
  func dismissMenu() {
    presentedMenu = nil
  }

  /// The Battle Mode `menu`'s tab shows: one of the menu's modes.
  func mode(of menu: TabMenu) -> RotationMode {
    switch menu {
      case .anarchy: .battle(anarchyMode)
      case .splatfestBattle: .splatfestBattle(splatfestForm)
    }
  }

  /// Switches the tab whose menu offers `mode` to it, and closes the menu.
  ///
  /// - Precondition: `mode` is one of a menu's modes.
  func choose(_ mode: RotationMode) {
    switch mode {
      case .battle(let battleMode):
        precondition(TabMenu.anarchy.modes.contains(mode), "No menu offers \(battleMode)")
        anarchyMode = battleMode

      case .splatfestBattle(let form):
        splatfestForm = form
    }
    presentedMenu = nil
  }
}
