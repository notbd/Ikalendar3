//
//  BattleModeParameter.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
import IkaCore

// MARK: - BattleModeParameter

/// The Battle Mode part of the Mode value as an App Intents parameter, for battle-only
/// consumers: the small, medium and large battle widgets, the Lock Screen widgets and the
/// chosen-Rule shortcut.
///
/// Its raw values are `ModeParameter`'s for the same Battle Modes. Configurations store them:
/// never rename a case's. `ParameterNameTests` keeps the names equal to `BattleMode.name(in:)`.
public enum BattleModeParameter: String, AppEnum {
  case regularBattle
  case anarchySeries
  case anarchyOpen
  case xBattle

  static public let typeDisplayRepresentation: TypeDisplayRepresentation = .init(
    name: LocalizedStringResource("Battle Mode", bundle: #bundle))

  static public let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .regularBattle: DisplayRepresentation(title: LocalizedStringResource("Regular Battle", bundle: #bundle)),
    .anarchySeries: DisplayRepresentation(title: LocalizedStringResource("Anarchy Battle (Series)", bundle: #bundle)),
    .anarchyOpen: DisplayRepresentation(title: LocalizedStringResource("Anarchy Battle (Open)", bundle: #bundle)),
    .xBattle: DisplayRepresentation(title: LocalizedStringResource("X Battle", bundle: #bundle)),
  ]
}

// MARK: BattleMode

extension BattleModeParameter {
  /// The parameter for a Battle Mode. A new Battle Mode fails to compile here until this type
  /// has a case for it.
  public init(_ battleMode: BattleMode) {
    self =
      switch battleMode {
        case .regular: .regularBattle
        case .anarchySeries: .anarchySeries
        case .anarchyOpen: .anarchyOpen
        case .x: .xBattle
      }
  }

  /// The Battle Mode chosen.
  public var battleMode: BattleMode {
    switch self {
      case .regularBattle: .regular
      case .anarchySeries: .anarchySeries
      case .anarchyOpen: .anarchyOpen
      case .xBattle: .x
    }
  }
}
