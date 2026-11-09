//
//  PreferenceStore.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Observation

// MARK: - PreferenceStore

/// The user's preferences and the app's first-run state, read and written through one
/// `UserDefaults` suite. Ship it on the App Group's suite, so the app, the widget extension and
/// the intents on one device all see the same values; a store reads the suite once, at init.
@Observable
final public class PreferenceStore {
  /// The tab the iPhone app opens on.
  public var defaultMode: ModeTab {
    didSet { defaults.set(defaultMode.rawValue, forKey: Key.defaultMode) }
  }

  /// The colour scheme the app asks for.
  public var colorScheme: ColorSchemePreference {
    didSet { defaults.set(colorScheme.rawValue, forKey: Key.colorScheme) }
  }

  /// The look of the app's own screens.
  public var style: Style {
    didSet { defaults.set(style.rawValue, forKey: Key.style) }
  }

  /// Minimizes the iPhone tab bar while scrolling.
  public var shouldMinimizeTabBar: Bool {
    didSet { defaults.set(shouldMinimizeTabBar, forKey: Key.shouldMinimizeTabBar) }
  }

  /// Reminds at the start of each Big Run.
  public var isBigRunReminderOn: Bool {
    didSet { defaults.set(isBigRunReminderOn, forKey: Key.isBigRunReminderOn) }
  }

  /// Reminds at the start of each Eggstra Work.
  public var isEggstraWorkReminderOn: Bool {
    didSet { defaults.set(isEggstraWorkReminderOn, forKey: Key.isEggstraWorkReminderOn) }
  }

  /// Reminds at the start of each Splatfest.
  public var isSplatfestReminderOn: Bool {
    didSet { defaults.set(isSplatfestReminderOn, forKey: Key.isSplatfestReminderOn) }
  }

  /// Reminds at the start of each Challenge's first window.
  public var isChallengeReminderOn: Bool {
    didSet { defaults.set(isChallengeReminderOn, forKey: Key.isChallengeReminderOn) }
  }

  /// The Mac window's last layout, which it reopens on.
  public var macLayout: MacLayout {
    didSet { defaults.set(macLayout.rawValue, forKey: Key.macLayout) }
  }

  /// True until the welcome screen has been shown once.
  public var shouldShowOnboarding: Bool {
    didSet { defaults.set(shouldShowOnboarding, forKey: Key.shouldShowOnboarding) }
  }

  /// True once the player has used the Rate row, which ends its nudge.
  public var hasDiscoveredRating: Bool {
    didSet { defaults.set(hasDiscoveredRating, forKey: Key.hasDiscoveredRating) }
  }

  @ObservationIgnored private let defaults: UserDefaults

  /// Reads every value from `defaults`; a value never written reads as its default.
  public init(defaults: UserDefaults) {
    self.defaults = defaults
    defaultMode = defaults.ikaEnum(forKey: Key.defaultMode, default: Default.defaultMode)
    colorScheme = defaults.ikaEnum(forKey: Key.colorScheme, default: Default.colorScheme)
    style = defaults.ikaEnum(forKey: Key.style, default: Default.style)
    shouldMinimizeTabBar = defaults.ikaBool(forKey: Key.shouldMinimizeTabBar, default: Default.shouldMinimizeTabBar)
    isBigRunReminderOn = defaults.ikaBool(forKey: Key.isBigRunReminderOn, default: Default.isReminderOn)
    isEggstraWorkReminderOn = defaults.ikaBool(forKey: Key.isEggstraWorkReminderOn, default: Default.isReminderOn)
    isSplatfestReminderOn = defaults.ikaBool(forKey: Key.isSplatfestReminderOn, default: Default.isReminderOn)
    isChallengeReminderOn = defaults.ikaBool(forKey: Key.isChallengeReminderOn, default: Default.isReminderOn)
    macLayout = defaults.ikaEnum(forKey: Key.macLayout, default: Default.macLayout)
    shouldShowOnboarding = defaults.ikaBool(forKey: Key.shouldShowOnboarding, default: Default.shouldShowOnboarding)
    hasDiscoveredRating = defaults.ikaBool(forKey: Key.hasDiscoveredRating, default: Default.hasDiscoveredRating)
  }

  /// Restores the onboarding and discovery flags (Debug Options' Reset App States) and nothing
  /// else.
  public func resetAppStates() {
    shouldShowOnboarding = Default.shouldShowOnboarding
    hasDiscoveredRating = Default.hasDiscoveredRating
  }

  /// Restores every value except the onboarding and discovery flags (Debug Options' Reset App
  /// Preferences) and touches nothing else.
  public func resetAppPreferences() {
    defaultMode = Default.defaultMode
    colorScheme = Default.colorScheme
    style = Default.style
    shouldMinimizeTabBar = Default.shouldMinimizeTabBar
    isBigRunReminderOn = Default.isReminderOn
    isEggstraWorkReminderOn = Default.isReminderOn
    isSplatfestReminderOn = Default.isReminderOn
    isChallengeReminderOn = Default.isReminderOn
    macLayout = Default.macLayout
  }
}

// MARK: PreferenceStore.Key

extension PreferenceStore {
  /// On-disk keys, new for ikalendar 3. Frozen once shipped: renaming one resets that value for
  /// every updating user. Pinned by `PreferenceStoreTests`.
  enum Key {
    static let defaultMode = "pref.default_mode"
    static let colorScheme = "pref.color_scheme"
    static let style = "pref.style"
    static let shouldMinimizeTabBar = "pref.should_minimize_tab_bar"
    static let isBigRunReminderOn = "pref.reminder.big_run"
    static let isEggstraWorkReminderOn = "pref.reminder.eggstra_work"
    static let isSplatfestReminderOn = "pref.reminder.splatfest"
    static let isChallengeReminderOn = "pref.reminder.challenge"
    static let macLayout = "pref.mac_layout"

    static let shouldShowOnboarding = "state.should_show_onboarding"
    static let hasDiscoveredRating = "state.has_discovered_rating"
  }
}

// MARK: PreferenceStore.Default

extension PreferenceStore {
  /// The values before the first write and after a reset.
  private enum Default {
    static let defaultMode: ModeTab = .regularBattle
    static let colorScheme: ColorSchemePreference = .dark
    static let style: Style = .ink
    static let shouldMinimizeTabBar = false
    static let isReminderOn = false
    static let macLayout: MacLayout = .columns

    static let shouldShowOnboarding = true
    static let hasDiscoveredRating = false
  }
}

// MARK: - UserDefaults

extension UserDefaults {
  /// Reads a value stored as its `String` raw value; a missing or unknown value reads as the
  /// default.
  fileprivate func ikaEnum<T: RawRepresentable>(forKey key: String, default defaultValue: T) -> T
    where T.RawValue == String
  {
    string(forKey: key).flatMap(T.init(rawValue:)) ?? defaultValue
  }

  /// Reads a `Bool` with a presence check: `bool(forKey:)` reads a missing key as false, which
  /// would break a default of true before the first write.
  fileprivate func ikaBool(forKey key: String, default defaultValue: Bool) -> Bool {
    object(forKey: key) as? Bool ?? defaultValue
  }
}
