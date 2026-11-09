//
//  MacLayout.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - MacLayout

/// How the Mac window shows the Schedules, switched from the toolbar and the View menu.
///
/// - Important: Raw values are the on-disk encoding. Frozen once shipped; pinned by
///   `PreferenceStoreTests`.
public enum MacLayout: String, CaseIterable, Hashable, Sendable {
  case columns
  case sidebar
  case overview
}
