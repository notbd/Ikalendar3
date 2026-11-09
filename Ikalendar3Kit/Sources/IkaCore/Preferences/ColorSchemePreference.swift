//
//  ColorSchemePreference.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - ColorSchemePreference

/// The colour scheme the app asks for: the system's, or always dark or light.
///
/// - Important: Raw values are the on-disk encoding. Frozen once shipped; pinned by
///   `PreferenceStoreTests`.
public enum ColorSchemePreference: String, CaseIterable, Hashable, Sendable {
  case followSystem = "follow_system"
  case dark
  case light
}
