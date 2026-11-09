//
//  RuleParameter.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
import IkaCore

// MARK: - RuleParameter

/// A Rule as an App Intents parameter, for the chosen-Rule shortcut. Tricolor Turf War is not
/// a choice: it is only played during a Splatfest.
///
/// Configurations store the raw value: never rename a case's. The names are the shipped locale
/// files' names, which `ParameterNameTests` checks in all 14 languages.
public enum RuleParameter: String, AppEnum {
  case turfWar
  case splatZones
  case towerControl
  case rainmaker
  case clamBlitz

  static public let typeDisplayRepresentation: TypeDisplayRepresentation = .init(
    name: LocalizedStringResource("Rule", bundle: #bundle))

  static public let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .turfWar: DisplayRepresentation(title: LocalizedStringResource("Turf War", bundle: #bundle)),
    .splatZones: DisplayRepresentation(title: LocalizedStringResource("Splat Zones", bundle: #bundle)),
    .towerControl: DisplayRepresentation(title: LocalizedStringResource("Tower Control", bundle: #bundle)),
    .rainmaker: DisplayRepresentation(title: LocalizedStringResource("Rainmaker", bundle: #bundle)),
    .clamBlitz: DisplayRepresentation(title: LocalizedStringResource("Clam Blitz", bundle: #bundle)),
  ]

  /// The Rule chosen, by Nintendo's id (`VsRule-0` is Turf War).
  public var rule: RuleID {
    switch self {
      case .turfWar: RuleID("VnNSdWxlLTA=")
      case .splatZones: RuleID("VnNSdWxlLTE=")
      case .towerControl: RuleID("VnNSdWxlLTI=")
      case .rainmaker: RuleID("VnNSdWxlLTM=")
      case .clamBlitz: RuleID("VnNSdWxlLTQ=")
    }
  }
}
