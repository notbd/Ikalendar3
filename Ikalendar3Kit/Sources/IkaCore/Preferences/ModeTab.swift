//
//  ModeTab.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - ModeTab

/// One of the five iPhone tabs, in tab bar order, and the values of the default Mode setting.
///
/// The Splatfest tab is not a member: while a Splatfest runs it replaces the first tab at run
/// time, so a default Mode of Regular Battle opens on the Splatfest tab then, and any other
/// default opens on its own tab.
///
/// - Important: Raw values are the on-disk encoding of the default Mode. Frozen once shipped;
///   pinned by `PreferenceStoreTests`.
public enum ModeTab: String, CaseIterable, Hashable, Sendable {
  case regularBattle = "regular_battle"
  /// Carries the Anarchy Series or Anarchy Open choice.
  case anarchy
  case xBattle = "x_battle"
  case challenge
  case salmonRun = "salmon_run"
}
