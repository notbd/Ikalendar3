//
//  Ikalendar3Widgets.swift
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
    SalmonRunWidget()
  }
}

// MARK: - WidgetKind

/// Each widget's kind, which WidgetKit stores with every placed widget: never rename a raw value.
enum WidgetKind: String {
  /// The widget set to one Battle Mode: Home Screen, StandBy, Mac desktop and Lock Screen.
  case battle
  /// The extra large widget with every Battle Mode.
  case battleOverview = "battle-overview"
  /// The Salmon Run widget.
  case salmonRun = "salmon-run"

  /// The kind of the widget a player sets to `mode`. Every Mode has a widget: the switch is
  /// exhaustive, so a new member of the Mode value fails to compile here until one covers it.
  /// Every Battle Mode shares the battle widget, which a configuration sets to one.
  init(_ mode: Mode) {
    switch mode {
      case .battle: self = .battle
      case .salmonRun: self = .salmonRun
    }
  }
}

// MARK: - WidgetsIntentsPackage

/// Adds `IkaIntents`' types, such as the Battle Mode parameter, to this extension's App Intents
/// metadata, so the widget editor offers them.
struct WidgetsIntentsPackage: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] { [IkaIntentsPackage.self] }
}
