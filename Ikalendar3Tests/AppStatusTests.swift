//
//  AppStatusTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import Ikalendar3

// MARK: - AppStatusTests

/// The tab selection, the Series and Open (or Open and Pro) menu and the Modes it picks.
struct AppStatusTests {
  @Test
  func `The Anarchy tab opens on Anarchy Series and the Splatfest tab on Splatfest Battle (Open)`() {
    let status: AppStatus = .init(selectedPlace: .anarchy)

    #expect(status.mode(of: .anarchy) == .battle(.anarchySeries))
    #expect(status.mode(of: .splatfestBattle) == .splatfestBattle(.open))
  }

  @Test
  func `Tapping another tab selects it and closes the menu`() {
    let status: AppStatus = .init(selectedPlace: .anarchy)
    status.select(.mode(.anarchy))

    status.select(.mode(.xBattle))

    #expect(status.selectedPlace == .xBattle)
    #expect(status.presentedMenu == nil)
  }

  @Test(arguments: [(AppTab.mode(.anarchy), TabMenu.anarchy), (.splatfest, .splatfestBattle)])
  func `A second tap on the selected Anarchy or Splatfest tab opens its menu and a third closes it`(
    _ tab: AppTab,
    _ menu: TabMenu)
  {
    let status: AppStatus = .init(selectedPlace: tab.place)

    status.select(tab)
    #expect(status.presentedMenu == menu)
    #expect(status.selectedPlace == tab.place)

    status.select(tab)
    #expect(status.presentedMenu == nil)
  }

  @Test(arguments: [AppTab.mode(.regularBattle), .mode(.xBattle), .mode(.challenge), .mode(.salmonRun)])
  func `A second tap on any other selected tab opens no menu`(_ tab: AppTab) {
    let status: AppStatus = .init(selectedPlace: tab.place)

    status.select(tab)

    #expect(status.presentedMenu == nil)
    #expect(status.selectedPlace == tab.place)
  }

  @Test(arguments: [
    RotationMode.battle(.anarchyOpen),
    .battle(.anarchySeries),
    .splatfestBattle(.pro),
    .splatfestBattle(.open),
  ])
  func `Picking an option switches its tab to that Mode and closes the menu`(_ mode: RotationMode) {
    let menu: TabMenu = if case .battle = mode { .anarchy } else { .splatfestBattle }
    let status: AppStatus = .init(selectedPlace: .anarchy)
    status.select(.mode(.anarchy))

    status.choose(mode)

    #expect(status.mode(of: menu) == mode)
    #expect(status.presentedMenu == nil)
  }
}
