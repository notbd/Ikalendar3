//
//  SidebarChoiceTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import Ikalendar3

// MARK: - SidebarChoiceTests

/// The iPad sidebar row the player picks, and the menus' choice it carries along.
struct SidebarChoiceTests {
  @Test
  func `The sidebar has no choice until the player picks a row, and then keeps it`() {
    let status: AppStatus = .init(selectedPlace: .xBattle)
    #expect(status.sidebarChoice == nil)

    status.pick(.challenge)

    #expect(status.sidebarChoice == .challenge)
    #expect(status.selectedPlace == .xBattle)
  }

  @Test(arguments: [
    (SidebarItem.mode(.battle(.anarchyOpen)), RotationMode.battle(.anarchyOpen), RotationMode.splatfestBattle(.open)),
    (.mode(.battle(.anarchySeries)), .battle(.anarchySeries), .splatfestBattle(.open)),
    (.splatfestBattle(.pro), .battle(.anarchySeries), .splatfestBattle(.pro)),
    (.mode(.battle(.x)), .battle(.anarchySeries), .splatfestBattle(.open)),
  ])
  func `Picking a form in the sidebar switches the menu that offers it too`(
    _ item: SidebarItem,
    _ anarchy: RotationMode,
    _ splatfestBattle: RotationMode)
  {
    let status: AppStatus = .init(selectedPlace: .regularBattle)

    status.pick(item)

    #expect(status.mode(of: .anarchy) == anarchy)
    #expect(status.mode(of: .splatfestBattle) == splatfestBattle)
  }
}
