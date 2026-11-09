//
//  Ikalendar3Widgets.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
import IkaDesign
import IkaIntents
import IkaResources
import SwiftUI
import WidgetKit

// MARK: - Ikalendar3Widgets

/// The widget extension on iPhone, iPad and Mac.
@main
struct Ikalendar3Widgets: WidgetBundle {
  /// Registers the fonts and points image lookups at the resource framework before anything draws.
  init() {
    BundledResources.load(from: IkaResources.bundle)
  }

  var body: some Widget {
    BattleWidget()
    BattleOverviewWidget()
  }
}

// MARK: - WidgetsIntentsPackage

/// Adds `IkaIntents`' types, such as the Battle Mode parameter, to this extension's App Intents
/// metadata, so the widget editor offers them.
struct WidgetsIntentsPackage: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] { [IkaIntentsPackage.self] }
}
