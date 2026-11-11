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

  /// How the selected tab shows its colour on the tab bar's glass over `style`'s ground in
  /// `colorScheme`: its Mode colour, as ikalendar 2 tints it. Splatfest Battle has no colour of its
  /// own and every Style draws it neutral, so the Splatfest tab takes the primary colour.
  ///
  /// The label and icon take the nearest tint of the Mode colour that reads as text (4.5:1) on the
  /// glass. Two Styles differ in light appearance:
  /// - Ink lies on a grey board, where the light glass turns mid grey and no such tint still reads
  ///   as the colour (Regular Battle's would be #292E00): the label stays primary and only the icon
  ///   takes the colour, at the 3:1 icons need.
  /// - Timeline keeps its page dark, and light glass over it flips between mid grey and dark with
  ///   what scrolls under it, so no one label colour reads on both: its tab bar is dark
  ///   (`barColorScheme`), which draws the selected label in its own white, and the icon takes the
  ///   tint of the dark bar.
  func selectedColor(style: Style, in colorScheme: ColorScheme) -> SelectedTabColor {
    guard case .mode(let tab) = self else { return .primary }

    let barScheme: ColorScheme = Self.barColorScheme(style: style, in: colorScheme)
    let glass: SRGBColor = Self.selectedGlass(style: style, in: barScheme)
    switch (style, colorScheme) {
      case (.ink, .light):
        return .icon(tab.color.base.readableTint(on: glass, for: .largeTextAndIcons))
      case (.timeline, .light):
        return .icon(tab.color.base.readableTint(on: glass, for: .text))
      default:
        return .tint(tab.color.base.readableTint(on: glass, for: .text))
    }
  }

  /// The tab bar's appearance over `style`'s ground: dark for Timeline, whose page is dark in both
  /// appearances; `colorScheme` for the others.
  static func barColorScheme(style: Style, in colorScheme: ColorScheme) -> ColorScheme {
    style == .timeline ? .dark : colorScheme
  }

  /// What the tab bar's glass shows behind the selected tab over `style`'s ground when the bar is
  /// in `barScheme`, at the end that is harder to read on, as measured from iOS 27.2 simulator
  /// captures: #1F1F20 to #3A3A3C when dark; when light, #E6E6E8 to #EFF2F3 over Classic (taken as
  /// #D8D8DC, for a margin) and #92928F over Ink's grey board (`InkBoard`, #969793). These are
  /// reference grounds, taken over each Style's plain ground: the glass also takes the colour of
  /// what scrolls under it, so over a bright Stage image a label can read lower than on them.
  static func selectedGlass(style: Style, in barScheme: ColorScheme) -> SRGBColor {
    switch (style, barScheme) {
      case (_, .dark),
           (.timeline, _): .init(hex: 0x3A3A3C)
      case (.ink, _): .init(hex: 0x92928F)
      case (.classic, _): .init(hex: 0xD8D8DC)
    }
  }
}

// MARK: - SelectedTabColor

/// How the selected tab shows its colour in the tab bar.
enum SelectedTabColor: Equatable {
  /// The label and the icon in this colour.
  case tint(SRGBColor)
  /// The label in the primary colour and the icon in this colour.
  case icon(SRGBColor)
  /// The label and the icon in the primary colour.
  case primary
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
