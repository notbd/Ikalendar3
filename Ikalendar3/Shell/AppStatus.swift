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
///
/// Every layout shares one selection, so a window that crosses a layout boundary shows what the
/// player chose last: the selected tab's place, which a sidebar row refines (`sidebarChoice`). A
/// pick in the sidebar selects its row's tab, and a tab or menu choice moves the sidebar to its
/// row. The columns show every Mode at once and leave it as it is.
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
  /// The iPad sidebar row the player picked, or `nil` when none was picked since the last tab
  /// choice: the sidebar then shows the selected tab's row (`sidebarItem(selectedTab:)`).
  private(set) var sidebarChoice: SidebarItem?
  /// Whether Settings is shown on iPhone and iPad.
  var isSettingsPresented = false
  /// The event whose Schedule the iPad's sheet shows, opened from its card in the event strip. It
  /// is kept here so the sheet stays open while the window switches layouts.
  var presentedEvent: EventSheet?
  /// The haptic the last refresh run ended with, which every layout plays; `nil` before the first.
  var refreshHaptic: RefreshHaptic?

  /// A status that opens on `selectedPlace`: the default Mode.
  init(selectedPlace: ModeTab) {
    self.selectedPlace = selectedPlace
  }

  /// The row the iPad sidebar selects: the row the player picked, else the row of `selectedTab`,
  /// the tab in `selectedPlace` at the instant shown.
  func sidebarItem(selectedTab: AppTab) -> SidebarItem {
    sidebarChoice ?? SidebarItem(selectedTab, anarchyMode: anarchyMode)
  }

  /// Picks `item` in the iPad sidebar and selects the tab that shows its screen. A form picked
  /// there is the menus' choice too, so the Anarchy and Splatfest views elsewhere show the form
  /// the player last picked.
  func pick(_ item: SidebarItem) {
    sidebarChoice = item
    selectedPlace = item.place
    presentedMenu = nil
    switch item {
      case .mode(.battle(let mode)) where TabMenu.anarchy.modes.contains(.battle(mode)):
        anarchyMode = mode
      case .splatfestBattle(let form):
        splatfestForm = form
      case .mode,
           .challenge,
           .eggstraWork,
           .splatfest,
           .tricolorTurfWar:
        break
    }
  }

  /// Handles a tap on `tab` in the tab bar. Another tab is selected, which the sidebar follows,
  /// and closes the menu; a second tap on the selected tab follows ticket 08's repeated-selection
  /// rule: it opens or closes the tab's menu, or leaves the system to scroll the list to the top.
  func select(_ tab: AppTab) {
    guard tab.place == selectedPlace else {
      selectedPlace = tab.place
      sidebarChoice = nil
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

  /// Closes the menu once the tab at the selected place no longer offers it, as when the
  /// Splatfest ends and its tab gives Regular Battle its place back, so the next Splatfest's tab
  /// does not open with its menu already shown.
  func closeMenu(unlessOfferedBy selectedTab: AppTab) {
    guard let menu = presentedMenu, selectedTab.repeatedSelectionAction != .openMenu(menu) else { return }

    presentedMenu = nil
  }

  /// The Battle Mode `menu`'s tab shows: one of the menu's modes.
  func mode(of menu: TabMenu) -> RotationMode {
    switch menu {
      case .anarchy: .battle(anarchyMode)
      case .splatfestBattle: .splatfestBattle(splatfestForm)
    }
  }

  /// Switches the tab or column whose menu offers `option` to its Battle Mode, and closes the
  /// menu. A sidebar row picked in the menu's other form moves to the option's.
  func choose(_ option: TabMenuOption) {
    switch option.mode {
      // Only the Anarchy menu offers continuous Battle Modes.
      case .battle(let mode):
        anarchyMode = mode
        if case .mode(.battle(let picked)) = sidebarChoice, TabMenu.anarchy.modes.contains(.battle(picked)) {
          sidebarChoice = .mode(.battle(mode))
        }

      case .splatfestBattle(let form):
        splatfestForm = form
        if case .splatfestBattle = sidebarChoice {
          sidebarChoice = .splatfestBattle(form)
        }
    }
    presentedMenu = nil
  }
}
