//
//  ModeParameter.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
import IkaCore

// MARK: - ModeParameter

/// The whole Mode value as an App Intents parameter, for the Control Center control, Tracking,
/// the start-Tracking intent and the now and next shortcuts.
///
/// Configurations store the raw value: never rename a case's. The names live in this module's
/// string catalog, because App Intents read them at build time; `ParameterNameTests` keeps them
/// equal to `Mode.name(in:)` in all 14 languages.
public enum ModeParameter: String, AppEnum {
  case regularBattle
  case anarchySeries
  case anarchyOpen
  case xBattle
  case salmonRun

  static public let typeDisplayRepresentation: TypeDisplayRepresentation = .init(
    name: LocalizedStringResource("type.mode", bundle: #bundle))

  static public let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .regularBattle: DisplayRepresentation(title: LocalizedStringResource("mode.regularBattle", bundle: #bundle)),
    .anarchySeries: DisplayRepresentation(title: LocalizedStringResource("mode.anarchySeries", bundle: #bundle)),
    .anarchyOpen: DisplayRepresentation(title: LocalizedStringResource("mode.anarchyOpen", bundle: #bundle)),
    .xBattle: DisplayRepresentation(title: LocalizedStringResource("mode.xBattle", bundle: #bundle)),
    .salmonRun: DisplayRepresentation(title: LocalizedStringResource("mode.salmonRun", bundle: #bundle)),
  ]
}

// MARK: Mode

extension ModeParameter {
  /// The parameter for a Mode. A new Mode or Battle Mode fails to compile here until this
  /// type has a case for it.
  public init(_ mode: Mode) {
    self =
      switch mode {
        case .battle(.regular): .regularBattle
        case .battle(.anarchySeries): .anarchySeries
        case .battle(.anarchyOpen): .anarchyOpen
        case .battle(.x): .xBattle
        case .salmonRun: .salmonRun
      }
  }

  /// The Mode chosen.
  public var mode: Mode {
    switch self {
      case .regularBattle: .battle(.regular)
      case .anarchySeries: .battle(.anarchySeries)
      case .anarchyOpen: .battle(.anarchyOpen)
      case .xBattle: .battle(.x)
      case .salmonRun: .salmonRun
    }
  }
}
