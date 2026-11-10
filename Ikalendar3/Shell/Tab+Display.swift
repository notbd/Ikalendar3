//
//  Tab+Display.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore

// MARK: - ModeTab

extension ModeTab {
  /// The game's name of the tab's Mode, which the tab bar and the default Mode picker show.
  var label: ModeLabel {
    switch self {
      case .regularBattle: .regularBattle
      case .anarchy: .anarchyBattle
      case .xBattle: .xBattle
      case .challenge: .challenges
      case .salmonRun: .salmonRun
    }
  }

  /// The tab's symbol: ikalendar 2's where it had the Mode.
  var systemImage: String {
    switch self {
      case .regularBattle: "paintbrush.fill"
      case .anarchy: "trophy.fill"
      case .xBattle: "crown.fill"
      case .challenge: "flag.checkered"
      case .salmonRun: "lifepreserver.fill"
    }
  }
}

// MARK: - AppTab

extension AppTab {
  /// The tab's name in the tab bar.
  func title(in language: GameLanguage) -> String {
    switch self {
      case .mode(let tab): tab.label.text(in: language)
      case .splatfest: ModeLabel.splatfestBattle.text(in: language)
    }
  }

  /// The tab's symbol in the tab bar.
  var systemImage: String {
    switch self {
      case .mode(let tab): tab.systemImage
      case .splatfest: "party.popper.fill"
    }
  }
}
