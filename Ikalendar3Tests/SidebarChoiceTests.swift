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

/// The one selection every iPad layout shares: a sidebar pick moves the tabs, a tab or menu
/// choice moves the sidebar, so a window that crosses a layout boundary shows what the player
/// chose last.
struct SidebarChoiceTests {
  @Test(arguments: [
    (SidebarItem.challenge, ModeTab.challenge),
    (.mode(.battle(.anarchyOpen)), .anarchy),
    (.eggstraWork, .salmonRun),
    (.splatfestBattle(.pro), .regularBattle),
  ])
  func `Picking a sidebar row selects the tab that shows its screen`(_ item: SidebarItem, _ place: ModeTab) {
    let status: AppStatus = .init(selectedPlace: .xBattle)

    status.pick(item)

    #expect(status.sidebarChoice == item)
    #expect(status.selectedPlace == place)
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

  @Test
  func `Until the player picks a row, the sidebar shows the selected tab's`() {
    let status: AppStatus = .init(selectedPlace: .salmonRun)

    #expect(status.sidebarChoice == nil)
    #expect(status.sidebarItem(selectedTab: .mode(.salmonRun)) == .mode(.salmonRun))
    #expect(status.sidebarItem(selectedTab: .splatfest) == .splatfest)
  }

  @Test
  func `Selecting another tab moves the sidebar to that tab's row, in the form its menu shows`() {
    let status: AppStatus = .init(selectedPlace: .regularBattle)
    status.pick(.challenge)

    status.select(.mode(.anarchy))
    status.choose(.battle(.anarchyOpen))

    #expect(status.sidebarItem(selectedTab: .mode(.anarchy)) == .mode(.battle(.anarchyOpen)))
  }

  @Test(arguments: [
    (
      SidebarItem.mode(.battle(.anarchySeries)),
      RotationMode.battle(.anarchyOpen),
      SidebarItem.mode(.battle(.anarchyOpen))),
    (.splatfestBattle(.open), .splatfestBattle(.pro), .splatfestBattle(.pro)),
    // A menu choice leaves a row of another Mode where it is.
    (.mode(.battle(.x)), .battle(.anarchyOpen), .mode(.battle(.x))),
    (.splatfest, .splatfestBattle(.pro), .splatfest),
  ])
  func `A menu choice moves the sidebar's row to the form it picks`(
    _ picked: SidebarItem,
    _ chosen: RotationMode,
    _ shown: SidebarItem)
  {
    let status: AppStatus = .init(selectedPlace: .regularBattle)
    status.pick(picked)

    status.choose(chosen)

    #expect(status.sidebarItem(selectedTab: .mode(.regularBattle)) == shown)
  }

  @Test
  func `The sidebar's row survives a round trip through the columns`() {
    let status: AppStatus = .init(selectedPlace: .regularBattle)
    status.pick(.mode(.battle(.x)))

    // In the columns, the Anarchy header's menu picks Open, and an event's sheet opens and closes.
    status.choose(.battle(.anarchyOpen))
    status.presentedEvent = .challenge
    status.presentedEvent = nil

    #expect(status.sidebarItem(selectedTab: .mode(.xBattle)) == .mode(.battle(.x)))
    #expect(status.selectedPlace == .xBattle)
    #expect(status.mode(of: .anarchy) == .battle(.anarchyOpen))
  }
}
