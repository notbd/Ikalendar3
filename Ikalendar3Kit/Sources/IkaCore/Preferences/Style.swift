//
//  Style.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - Style

/// The look of the app's own screens, picked in Settings (ADR 0005). Widgets, Live Activities
/// and the watch always use Ink.
///
/// - Important: Raw values are the on-disk encoding. Frozen once shipped; pinned by
///   `PreferenceStoreTests`.
public enum Style: String, CaseIterable, Hashable, Sendable {
  /// ikalendar 2's look.
  case classic
  /// ikalendar 2's layout on the game's materials.
  case ink
  /// SplatNet 3's schedule page.
  case timeline
}
