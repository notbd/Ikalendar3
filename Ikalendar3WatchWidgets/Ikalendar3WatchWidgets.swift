//
//  Ikalendar3WatchWidgets.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
import IkaCore
import IkaDesign
import IkaIntents
import IkaResources
import SwiftUI
import WidgetKit

// MARK: - Ikalendar3WatchWidgets

/// The watch widget extension: the complications in four families on the watch face, and the
/// Smart Stack widget. Each is set to one Mode, which the system's editor offers as one choice
/// per Mode, so the watch needs no settings screen of its own.
@main
struct Ikalendar3WatchWidgets: WidgetBundle {
  /// Registers the fonts and points image lookups at the resource framework before anything draws.
  init() {
    BundledResources.load(from: IkaResources.bundle)
  }

  var body: some Widget {
    ModeComplication()
    SmartStackWidget()
  }
}

extension Ikalendar3WatchWidgets {
  /// The app language, resolved for this extension's bundle. It declares the watch app's 14
  /// localizations, so it resolves the watch app's.
  nonisolated static let language: GameLanguage = .init(resolvedFor: .main)
}

// MARK: - WatchWidgetKind

/// Each watch widget's kind, which WidgetKit stores with every placed complication: never rename
/// a raw value.
enum WatchWidgetKind: String {
  /// The complication set to one Mode, in every family a watch face offers.
  case complication
  /// The Smart Stack widget set to one Mode.
  case smartStack = "smart-stack"
}

// MARK: - WatchWidgetsIntentsPackage

/// Adds `IkaIntents`' Mode parameter to this extension's App Intents metadata, so the
/// complication editor and the Smart Stack offer it.
struct WatchWidgetsIntentsPackage: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] { [IkaIntentsPackage.self] }
}
