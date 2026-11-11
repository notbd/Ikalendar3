//
//  Tab+Display.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaDesign
import SwiftUI

// MARK: - ModeTab

extension ModeTab {
  /// The game's name of the tab's Mode, which the default Mode picker shows and VoiceOver reads
  /// for the tab.
  var label: ModeLabel {
    switch self {
      case .regularBattle: .regularBattle
      case .anarchy: .anarchyBattle
      case .xBattle: .xBattle
      case .challenge: .challenges
      case .salmonRun: .salmonRun
    }
  }

  /// The tab's short name in the tab bar, as players say it, so five fit side by side.
  var shortTitle: TabText {
    switch self {
      case .regularBattle: .regularBattle
      case .anarchy: .anarchy
      case .xBattle: .xBattle
      case .challenge: .challenge
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

  /// The tab's Mode colour.
  var color: ModeColor {
    switch self {
      case .regularBattle: .regularBattle
      case .anarchy: .anarchy
      case .xBattle: .xBattle
      case .challenge: .challenge
      case .salmonRun: .salmonRun
    }
  }
}

// MARK: - AppTab

extension AppTab {
  /// The tab's full name, which VoiceOver reads.
  func title(in language: GameLanguage) -> String {
    switch self {
      case .mode(let tab): tab.label.text(in: language)
      case .splatfest: ModeLabel.splatfestBattle.text(in: language)
    }
  }

  /// The tab's name in the tab bar: its short name, or "Splatfest" for Splatfest Battle.
  func shortTitle(in language: GameLanguage) -> String {
    switch self {
      case .mode(let tab): tab.shortTitle.text(in: language)
      case .splatfest: ModeLabel.splatfest.text(in: language)
    }
  }

  /// The tab's symbol in the tab bar.
  var systemImage: String {
    switch self {
      case .mode(let tab): tab.systemImage
      case .splatfest: "party.popper.fill"
    }
  }

  /// The selected tab's colour, as ikalendar 2 tints it: its Mode colour, or for the Splatfest
  /// tab its first team's, in the nearest tint that reads as text on the tab bar's glass in
  /// `colorScheme`. `nil` for a Splatfest with no team colours known.
  func tint(in colorScheme: ColorScheme, splatfestColors: [SRGBColor]) -> SRGBColor? {
    let base: SRGBColor? =
      switch self {
        case .mode(let tab): tab.color.base
        case .splatfest: splatfestColors.first
      }
    return base?.readableTint(on: Self.tabBarGlass(in: colorScheme), for: .text)
  }

  /// What the tab bar's glass shows behind its items over the app's own ground, at the end that
  /// is harder to read on: about #1F1F20 to #3A3A3C in dark appearance and #E6E6E8 to #EFF2F3 in
  /// light, as measured on iOS 26, with a margin on the light side.
  static private func tabBarGlass(in colorScheme: ColorScheme) -> SRGBColor {
    colorScheme == .dark ? .init(hex: 0x3A3A3C) : .init(hex: 0xD8D8DC)
  }
}

// MARK: - TabText

/// The tab bar's short Mode names, from the app's `Tabs` string table. The raw value is the
/// catalog key. Each is the name players of the language use, short enough that five tabs fit;
/// the full name stays VoiceOver's label (`ModeTab.label`).
enum TabText: String, CaseIterable {
  /// "Regular".
  case regularBattle = "tab.regularBattle"
  /// "Anarchy".
  case anarchy = "tab.anarchy"
  /// "X Battle".
  case xBattle = "tab.xBattle"
  /// "Challenges".
  case challenge = "tab.challenge"
  /// "Salmon Run".
  case salmonRun = "tab.salmonRun"

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.main.localizedString(forKey: rawValue, table: "Tabs", in: language)
  }
}
