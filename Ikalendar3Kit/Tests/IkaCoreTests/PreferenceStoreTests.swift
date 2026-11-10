//
//  PreferenceStoreTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - PreferenceStoreTests

struct PreferenceStoreTests {
  /// This test's own suite, deleted when the test ends.
  private let testDefaults: TestDefaults
  private var defaults: UserDefaults { testDefaults.defaults }

  init() throws {
    testDefaults = try TestDefaults()
  }

  @Test
  func `Fresh suite reads the documented defaults`() {
    let store: PreferenceStore = .init(defaults: defaults)

    #expect(store.defaultMode == .regularBattle)
    #expect(store.colorScheme == .dark)
    #expect(store.style == .ink)
    #expect(!store.shouldMinimizeTabBar)
    #expect(!store.isBigRunReminderOn)
    #expect(!store.isEggstraWorkReminderOn)
    #expect(!store.isSplatfestReminderOn)
    #expect(!store.isChallengeReminderOn)
    #expect(store.macLayout == .columns)
    #expect(store.shouldShowOnboarding)
    #expect(!store.hasDiscoveredRating)
  }

  @Test
  func `Stored values survive a new store on the same suite`() {
    let first: PreferenceStore = .init(defaults: defaults)
    first.setEveryValueAwayFromItsDefault()

    let second: PreferenceStore = .init(defaults: defaults)

    #expect(second.defaultMode == .salmonRun)
    #expect(second.colorScheme == .light)
    #expect(second.style == .timeline)
    #expect(second.shouldMinimizeTabBar)
    #expect(second.isBigRunReminderOn)
    #expect(second.isEggstraWorkReminderOn)
    #expect(second.isSplatfestReminderOn)
    #expect(second.isChallengeReminderOn)
    #expect(second.macLayout == .overview)
    #expect(!second.shouldShowOnboarding)
    #expect(second.hasDiscoveredRating)
  }

  @Test
  func `Assigning a value the store already has writes nothing`() {
    let store: PreferenceStore = .init(defaults: defaults)

    store.defaultMode = store.defaultMode
    store.colorScheme = store.colorScheme
    store.style = store.style
    store.shouldMinimizeTabBar = store.shouldMinimizeTabBar
    store.isBigRunReminderOn = store.isBigRunReminderOn
    store.isEggstraWorkReminderOn = store.isEggstraWorkReminderOn
    store.isSplatfestReminderOn = store.isSplatfestReminderOn
    store.isChallengeReminderOn = store.isChallengeReminderOn
    store.macLayout = store.macLayout
    store.shouldShowOnboarding = store.shouldShowOnboarding
    store.hasDiscoveredRating = store.hasDiscoveredRating

    #expect(defaults.persistentDomain(forName: testDefaults.name)?.isEmpty ?? true)
  }

  // MARK: - Resets

  @Test
  func `Reset app states restores only the onboarding and discovery flags`() {
    defaults.set("kept", forKey: "unrelated")
    let store: PreferenceStore = .init(defaults: defaults)
    store.setEveryValueAwayFromItsDefault()

    store.resetAppStates()

    for reread in [store, PreferenceStore(defaults: defaults)] {
      #expect(reread.shouldShowOnboarding)
      #expect(!reread.hasDiscoveredRating)

      #expect(reread.defaultMode == .salmonRun)
      #expect(reread.colorScheme == .light)
      #expect(reread.style == .timeline)
      #expect(reread.shouldMinimizeTabBar)
      #expect(reread.isBigRunReminderOn)
      #expect(reread.isEggstraWorkReminderOn)
      #expect(reread.isSplatfestReminderOn)
      #expect(reread.isChallengeReminderOn)
      #expect(reread.macLayout == .overview)
    }
    #expect(defaults.string(forKey: "unrelated") == "kept")
  }

  @Test
  func `Reset app preferences restores everything but the app states`() {
    defaults.set("kept", forKey: "unrelated")
    let store: PreferenceStore = .init(defaults: defaults)
    store.setEveryValueAwayFromItsDefault()

    store.resetAppPreferences()

    for reread in [store, PreferenceStore(defaults: defaults)] {
      #expect(reread.defaultMode == .regularBattle)
      #expect(reread.colorScheme == .dark)
      #expect(reread.style == .ink)
      #expect(!reread.shouldMinimizeTabBar)
      #expect(!reread.isBigRunReminderOn)
      #expect(!reread.isEggstraWorkReminderOn)
      #expect(!reread.isSplatfestReminderOn)
      #expect(!reread.isChallengeReminderOn)
      #expect(reread.macLayout == .columns)

      #expect(!reread.shouldShowOnboarding)
      #expect(reread.hasDiscoveredRating)
    }
    #expect(defaults.string(forKey: "unrelated") == "kept")
  }

  // MARK: - On-disk format (golden)

  // Keys and raw values are spelled out as literals on purpose: a renamed key or raw value
  // silently resets that value for every updating user, so it must fail here. Never rewrite
  // these literals in terms of `PreferenceStore.Key` or `rawValue`.

  @Test
  func `Writes land under the frozen keys as the frozen encodings`() {
    PreferenceStore(defaults: defaults).setEveryValueAwayFromItsDefault()

    #expect(defaults.string(forKey: "pref.default_mode") == "salmon_run")
    #expect(defaults.string(forKey: "pref.color_scheme") == "light")
    #expect(defaults.string(forKey: "pref.style") == "timeline")
    #expect(defaults.object(forKey: "pref.should_minimize_tab_bar") as? Bool == true)
    #expect(defaults.object(forKey: "pref.reminder.big_run") as? Bool == true)
    #expect(defaults.object(forKey: "pref.reminder.eggstra_work") as? Bool == true)
    #expect(defaults.object(forKey: "pref.reminder.splatfest") as? Bool == true)
    #expect(defaults.object(forKey: "pref.reminder.challenge") as? Bool == true)
    #expect(defaults.string(forKey: "pref.mac_layout") == "overview")
    #expect(defaults.object(forKey: "state.should_show_onboarding") as? Bool == false)
    #expect(defaults.object(forKey: "state.has_discovered_rating") as? Bool == true)
  }

  @Test
  func `Values stored under the frozen keys load`() {
    // Every value differs from its default, so a renamed key cannot pass via the fallback.
    defaults.set("challenge", forKey: "pref.default_mode")
    defaults.set("follow_system", forKey: "pref.color_scheme")
    defaults.set("classic", forKey: "pref.style")
    defaults.set(true, forKey: "pref.should_minimize_tab_bar")
    defaults.set(true, forKey: "pref.reminder.big_run")
    defaults.set(true, forKey: "pref.reminder.eggstra_work")
    defaults.set(true, forKey: "pref.reminder.splatfest")
    defaults.set(true, forKey: "pref.reminder.challenge")
    defaults.set("sidebar", forKey: "pref.mac_layout")
    defaults.set(false, forKey: "state.should_show_onboarding")
    defaults.set(true, forKey: "state.has_discovered_rating")

    let store: PreferenceStore = .init(defaults: defaults)

    #expect(store.defaultMode == .challenge)
    #expect(store.colorScheme == .followSystem)
    #expect(store.style == .classic)
    #expect(store.shouldMinimizeTabBar)
    #expect(store.isBigRunReminderOn)
    #expect(store.isEggstraWorkReminderOn)
    #expect(store.isSplatfestReminderOn)
    #expect(store.isChallengeReminderOn)
    #expect(store.macLayout == .sidebar)
    #expect(!store.shouldShowOnboarding)
    #expect(store.hasDiscoveredRating)
  }

  @Test
  func `Every raw value encoding is frozen`() {
    // A new case without a golden entry fails too, which forces a decision on its encoding.
    let modeTabs: [ModeTab: String] = [
      .regularBattle: "regular_battle",
      .anarchy: "anarchy",
      .xBattle: "x_battle",
      .challenge: "challenge",
      .salmonRun: "salmon_run",
    ]
    let colorSchemes: [ColorSchemePreference: String] = [
      .followSystem: "follow_system",
      .dark: "dark",
      .light: "light",
    ]
    let styles: [Style: String] = [
      .classic: "classic",
      .ink: "ink",
      .timeline: "timeline",
    ]
    let macLayouts: [MacLayout: String] = [
      .columns: "columns",
      .sidebar: "sidebar",
      .overview: "overview",
    ]

    for tab in ModeTab.allCases { #expect(tab.rawValue == modeTabs[tab]) }
    for scheme in ColorSchemePreference.allCases { #expect(scheme.rawValue == colorSchemes[scheme]) }
    for style in Style.allCases { #expect(style.rawValue == styles[style]) }
    for layout in MacLayout.allCases { #expect(layout.rawValue == macLayouts[layout]) }
  }

  @Test
  func `The reminder kinds are the switches that are on, both ways`() {
    let store: PreferenceStore = .init(defaults: defaults)
    #expect(store.reminderKinds.isEmpty)

    store.isBigRunReminderOn = true
    store.isChallengeReminderOn = true
    #expect(store.reminderKinds == [.bigRun, .challenge])

    store.reminderKinds = [.eggstraWork, .splatfest]
    #expect(!store.isBigRunReminderOn)
    #expect(store.isEggstraWorkReminderOn)
    #expect(store.isSplatfestReminderOn)
    #expect(!store.isChallengeReminderOn)
  }

  @Test
  func `The stored reminder kinds are the suite's, written by any store on it since`() {
    let copy: PreferenceStore = .init(defaults: defaults)
    let settings: PreferenceStore = .init(defaults: defaults)

    settings.reminderKinds = [.bigRun, .eggstraWork]
    settings.isBigRunReminderOn = false

    #expect(copy.reminderKinds.isEmpty)
    #expect(copy.storedReminderKinds == [.eggstraWork])
  }

  @Test
  func `Five tabs in tab bar order`() {
    #expect(ModeTab.allCases == [.regularBattle, .anarchy, .xBattle, .challenge, .salmonRun])
  }
}

// MARK: - ResetAllTests

/// Reset All through the preferences store and the cache it must leave alone.
@MainActor
final class ResetAllTests {
  private let testDefaults: TestDefaults
  private var defaults: UserDefaults { testDefaults.defaults }
  private let directory: URL
  private let transport: ScriptedTransport = .init()
  private let clock: SettableClock = .init(date("2026-10-20T12:05:00Z"))

  init() throws {
    testDefaults = try TestDefaults()
    directory = try makeTestDirectory()
  }

  deinit {
    try? FileManager.default.removeItem(at: directory)
  }

  /// Debug Options ship in Release builds, so Reset All must never reach the cache or its attempt
  /// records: clearing a record would let anyone bypass splatoon3.ink's hourly limit.
  @Test
  func `Reset all restores every value and leaves the cache and its attempt records as they were`() async throws {
    try transport.scriptFeeds()
    await RefreshEngine(directory: directory, transport: transport, clock: clock).refresh()
    let filesBefore = try storedFiles()
    defaults.set("kept", forKey: "unrelated")
    let store: PreferenceStore = .init(defaults: defaults)
    store.setEveryValueAwayFromItsDefault()

    store.resetAll()

    for reread in [store, PreferenceStore(defaults: defaults)] {
      #expect(reread.defaultMode == .regularBattle)
      #expect(reread.colorScheme == .dark)
      #expect(reread.style == .ink)
      #expect(!reread.shouldMinimizeTabBar)
      #expect(!reread.isBigRunReminderOn)
      #expect(!reread.isEggstraWorkReminderOn)
      #expect(!reread.isSplatfestReminderOn)
      #expect(!reread.isChallengeReminderOn)
      #expect(reread.macLayout == .columns)
      #expect(reread.shouldShowOnboarding)
      #expect(!reread.hasDiscoveredRating)
    }
    #expect(defaults.string(forKey: "unrelated") == "kept")
    #expect(try storedFiles() == filesBefore)
    // The attempt records still close the gate for the hour.
    let again = await RefreshEngine(directory: directory, transport: transport, clock: clock).refresh()
    #expect(transport.requests.count == 3)
    #expect(again.outcomes == [.schedules: .gateClosed, .festivals: .gateClosed, .locale(.enUS): .gateClosed])
  }

  /// Every file in the test's directory by its relative path, with its bytes: the cache records,
  /// the attempt records and their lock.
  private func storedFiles() throws -> [String: Data] {
    let root = directory.path(percentEncoded: false)
    let files = FileManager.default
      .enumerator(at: directory, includingPropertiesForKeys: nil)?
      .compactMap { $0 as? URL }
      .filter { !$0.hasDirectoryPath } ?? []
    return try Dictionary(uniqueKeysWithValues: files.map { file in
      try (String(file.path(percentEncoded: false).dropFirst(root.count)), Data(contentsOf: file))
    })
  }
}

// MARK: - Helpers

extension PreferenceStore {
  /// Sets every value to one that differs from its default, so a value that fails to persist
  /// cannot pass by reading back as the default.
  fileprivate func setEveryValueAwayFromItsDefault() {
    defaultMode = .salmonRun
    colorScheme = .light
    style = .timeline
    shouldMinimizeTabBar = true
    isBigRunReminderOn = true
    isEggstraWorkReminderOn = true
    isSplatfestReminderOn = true
    isChallengeReminderOn = true
    macLayout = .overview
    shouldShowOnboarding = false
    hasDiscoveredRating = true
  }
}
