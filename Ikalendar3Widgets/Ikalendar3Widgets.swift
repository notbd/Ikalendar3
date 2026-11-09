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

/// The widget extension on iPhone, iPad and Mac, with Tracking's Live Activity on iOS.
@main
struct Ikalendar3Widgets: WidgetBundle {
  /// Registers the fonts and points image lookups at the resource framework before anything draws.
  init() {
    BundledResources.load(from: IkaResources.bundle)
  }

  var body: some Widget {
    BattleWidget()
    BattleOverviewWidget()
    #if os(iOS)
    TrackingLiveActivity()
    #endif
  }
}

// MARK: - WidgetsIntentsPackage

/// Adds `IkaIntents`' types, such as the Battle Mode parameter and the Live Activity's Refresh
/// intent, to this extension's App Intents metadata, so the widget editor offers them and the
/// activity's button finds its intent.
struct WidgetsIntentsPackage: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] { [IkaIntentsPackage.self] }
}
