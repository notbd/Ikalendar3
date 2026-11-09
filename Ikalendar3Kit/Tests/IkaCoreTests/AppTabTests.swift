//
//  AppTabTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct AppTabTests {
  /// A fixture at an instant, and whether the Splatfest tab is first then.
  struct TabSetCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let isSplatfestFirst: Bool

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  static let modeTabs: [AppTab] = [
    .mode(.regularBattle),
    .mode(.anarchy),
    .mode(.xBattle),
    .mode(.challenge),
    .mode(.salmonRun),
  ]
  static let splatfestTabs: [AppTab] = [
    .splatfest,
    .mode(.anarchy),
    .mode(.xBattle),
    .mode(.challenge),
    .mode(.salmonRun),
  ]

  @Test(arguments: [
    TabSetCase(fixture: .normalDay, instant: "2026-10-20T13:00:00Z", isSplatfestFirst: false),
    // Announced: not yet. The Splatfest starts on time with no new fetch.
    TabSetCase(fixture: .splatfestAnnounced, instant: "2026-10-30T23:59:59Z", isSplatfestFirst: false),
    TabSetCase(fixture: .splatfestAnnounced, instant: "2026-10-31T00:00:00Z", isSplatfestFirst: true),
    // First half and second half.
    TabSetCase(fixture: .splatfestFirstHalf, instant: "2026-10-31T12:00:00Z", isSplatfestFirst: true),
    TabSetCase(fixture: .splatfestSecondHalf, instant: "2026-11-01T05:23:00Z", isSplatfestFirst: true),
    // Its last second, then over.
    TabSetCase(fixture: .splatfestEnd, instant: "2026-08-23T23:59:59Z", isSplatfestFirst: true),
    TabSetCase(fixture: .splatfestEnd, instant: "2026-08-24T00:00:00Z", isSplatfestFirst: false),
  ])
  func `The first tab is Splatfest exactly while a Splatfest runs`(_ tabSet: TabSetCase) async throws {
    let snapshot = try await Snapshot.schedules(tabSet.fixture)

    let tabs = snapshot.tabs(at: date(tabSet.instant))

    #expect(tabs == (tabSet.isSplatfestFirst ? Self.splatfestTabs : Self.modeTabs))
  }

  @Test
  func `The five Mode tabs show before the schedules feed's first good response`() {
    #expect(Snapshot().tabs(at: TestData.epoch) == Self.modeTabs)
  }

  @Test
  func `The Splatfest tab takes Regular Battle's place, so a default Mode of Regular Battle opens on it`()
    async throws
  {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let instant = date("2026-11-01T05:23:00Z")

    #expect(AppTab.splatfest.place == .regularBattle)
    #expect(snapshot.tab(in: .regularBattle, at: instant) == .splatfest)
    for place in ModeTab.allCases.dropFirst() {
      #expect(snapshot.tab(in: place, at: instant) == .mode(place))
      #expect(AppTab.mode(place).place == place)
    }
  }

  /// Every tab and what a second tap on it does while it is selected.
  static let repeatedSelections: [(AppTab, RepeatedSelectionAction)] = [
    (.mode(.regularBattle), .scrollToTop),
    (.mode(.anarchy), .openMenu(.anarchy)),
    (.mode(.xBattle), .scrollToTop),
    (.mode(.challenge), .scrollToTop),
    (.mode(.salmonRun), .scrollToTop),
    (.splatfest, .openMenu(.splatfestBattle)),
  ]

  @Test(arguments: repeatedSelections)
  func `A second tap on the selected tab opens its menu on Anarchy and Splatfest and scrolls to the top elsewhere`(
    _ tab: AppTab,
    _ action: RepeatedSelectionAction)
  {
    #expect(tab.repeatedSelectionAction == action)
  }

  @Test
  func `The repeated-selection cases cover every tab`() {
    #expect(Self.repeatedSelections.map(\.0).count == AppTab.allCases.count)
    #expect(Set(Self.repeatedSelections.map(\.0)) == Set(AppTab.allCases))
  }
}
