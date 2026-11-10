//
//  ModeColor.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - ModeColor

/// SplatNet 3's colour of a Mode or event. A view always draws it with the Mode's icon or name,
/// so colour is never the only signal.
///
/// Splatfest has no member: it uses its teams' colours from the feed, made readable with
/// `SRGBColor.readableTint(on:for:)`.
public enum ModeColor: CaseIterable, Hashable, Sendable {
  /// Regular Battle.
  case regularBattle
  /// Anarchy Battle, Series and Open alike.
  case anarchy
  /// X Battle.
  case xBattle
  /// Challenges.
  case challenge
  /// Salmon Run and its regular Shifts.
  case salmonRun
  /// Big Run.
  case bigRun
  /// Eggstra Work.
  case eggstraWork

  /// The colour of `mode`.
  public init(_ mode: Mode) {
    switch mode {
      case .battle(let battleMode): self.init(battleMode)
      case .salmonRun: self = .salmonRun
    }
  }

  /// The colour of `battleMode`.
  public init(_ battleMode: BattleMode) {
    switch battleMode {
      case .regular: self = .regularBattle
      case .anarchySeries,
           .anarchyOpen: self = .anarchy
      case .x: self = .xBattle
    }
  }

  /// The colour of a Shift of `kind`.
  public init(_ kind: Shift.Kind) {
    switch kind {
      case .regular: self = .salmonRun
      case .bigRun: self = .bigRun
      case .eggstraWork: self = .eggstraWork
    }
  }

  /// The colour of a Mode summary: its Mode's, or the Shift kind's while a Big Run is Salmon Run's
  /// current Shift; `nil` for a form of Splatfest Battle, which has no colour of its own.
  public init?(_ summary: ModeSummary) {
    switch summary {
      case .battle(let mode, _): self.init(mode)
      case .splatfestBattle: return nil
      case .salmonRun(.running(let running)): self.init(running.item.kind)
      case .salmonRun: self = .salmonRun
    }
  }

  /// The colour as SplatNet 3's style sheet defines it.
  public var base: SRGBColor {
    switch self {
      case .regularBattle: .init(hex: 0xEAFF3E)
      case .anarchy: .init(hex: 0xF54910)
      case .xBattle: .init(hex: 0x0FDB9B)
      // Provisional: SplatNet 3 also defines #ea4074; ticket 54 picks one with the Challenge card.
      case .challenge: .init(hex: 0xF02D7D)
      case .salmonRun: .init(hex: 0xFF5033)
      case .bigRun: .init(hex: 0xB322FF)
      case .eggstraWork: .init(hex: 0xFDD400)
    }
  }

  /// The colour as text or an icon on `style`'s panel in `colorScheme`: the base colour, or its
  /// nearest tint that reaches `target` there.
  public func onPanel(of style: Style, in colorScheme: ColorScheme, for target: ContrastTarget) -> ColorPair {
    let panel: SRGBColor = style.panel(in: colorScheme)
    return ColorPair(foreground: base.readableTint(on: panel, for: target), background: panel)
  }

  /// The colour as a fill, such as a tag or a time pin, with black or white text and icons on it.
  /// The same in every Style and appearance.
  public var asFill: ColorPair {
    ColorPair(foreground: base.labelColor, background: base)
  }
}

// MARK: - ColorPair

/// A foreground and the background it is drawn on.
public struct ColorPair: Hashable, Sendable {
  /// The colour of the text or icon.
  public let foreground: SRGBColor
  /// The colour behind it.
  public let background: SRGBColor

  /// The pair's WCAG 2 contrast ratio.
  public var contrastRatio: Double {
    foreground.contrastRatio(with: background)
  }
}
