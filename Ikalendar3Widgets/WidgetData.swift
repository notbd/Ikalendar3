//
//  WidgetData.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - WidgetData

/// Where the widgets' language comes from. Their data is the App Group cache
/// (`AppGroup.cachedSnapshot()`), or a recorded day in previews (`Snapshot.preview(_:)`).
enum WidgetData {
  /// The app language, resolved for this extension's bundle. The extension declares the app's 14
  /// localizations, so it resolves the app's.
  static let language: GameLanguage = .init(resolvedFor: .main)
}
