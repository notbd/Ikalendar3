//
//  SidebarText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - SidebarText

/// The iPad sidebar's own strings and its toolbar's, from `IkaDesign`'s `Sidebar` string table.
/// The raw value is the catalog key. Mode names and labels come from `IkaCore`'s shared vocabulary.
public enum SidebarText: String, CaseIterable, Sendable {
  /// "Battle": the group of the four continuous Battle Modes.
  case battleGroup = "sidebar.group.battle"
  /// "Events": the group of Challenges.
  case eventsGroup = "sidebar.group.events"
  /// "Starts %@", with the time an event's next window starts.
  case startsAt = "sidebar.startsAt"
  /// "None announced yet": Challenges while none is announced.
  case noneAnnounced = "sidebar.noneAnnounced"
  /// "Refresh": the toolbar refresh button.
  case refresh = "sidebar.refresh"
  /// "Refreshing": the toolbar refresh button while a refresh runs.
  case refreshing = "sidebar.refreshing"

  /// The string in a text set, its placeholders filled in.
  public func text(in language: GameLanguage, _ arguments: any CVarArg...) -> String {
    let template = Bundle.module.localizedString(forKey: rawValue, table: "Sidebar", in: language)
    return arguments.isEmpty
      ? template
      : String(format: template, locale: Locale(identifier: language.rawValue), arguments: arguments)
  }
}

// MARK: - SidebarGroup.Kind

extension SidebarGroup.Kind {
  /// The group's title in the sidebar.
  public func title(in language: GameLanguage) -> String {
    switch self {
      case .splatfest: ModeLabel.splatfest.text(in: language)
      case .battle: SidebarText.battleGroup.text(in: language)
      case .events: SidebarText.eventsGroup.text(in: language)
      case .salmonRun: ModeLabel.salmonRun.text(in: language)
    }
  }
}
