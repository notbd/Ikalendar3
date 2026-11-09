//
//  Haptic.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - Haptic

/// ikalendar 2's event-to-haptic table, played through SwiftUI's sensory feedback. Haptics stay
/// in the app. Settings shown, a rigid impact, joins the table with Settings.
enum Haptic {
  /// A tab or Mode switch.
  static let modeSwitch: SensoryFeedback = .impact(flexibility: .soft)

  /// The haptic of a change in the engine's status: a medium impact when a refresh ends with
  /// every feed loaded, the error pattern when one failed, and none when a refresh starts,
  /// because pull to refresh plays its own.
  static func refreshChanged(from old: RefreshStatus, to new: RefreshStatus) -> SensoryFeedback? {
    guard old == .loading else { return nil }

    switch new {
      case .loading: return nil
      case .loaded: return .impact(weight: .medium)
      case .failed: return .error
    }
  }
}
