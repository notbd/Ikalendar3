//
//  Haptic.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaIntents
import SwiftUI

// MARK: - Haptic

/// ikalendar 2's event-to-haptic table, played through SwiftUI's sensory feedback. Haptics stay
/// in the app.
enum Haptic {
  /// A tab or Mode switch.
  static let modeSwitch: SensoryFeedback = .impact(flexibility: .soft)

  /// The haptic of Settings being shown or dismissed: a rigid impact when it is shown.
  static func settingsPresentationChanged(to isPresented: Bool) -> SensoryFeedback? {
    isPresented ? .impact(flexibility: .rigid) : nil
  }

  /// The haptic of a refresh run that ended with `outcomes`, on ikalendar 2's events: the error
  /// pattern when a feed failed, else a medium impact for a refresh the player asked for (pull to
  /// refresh) or one that sent a request. An activation run the gate kept entirely from the
  /// network loaded nothing, so it plays none. A refresh that starts plays none either, because
  /// pull to refresh plays its own.
  static func refreshEnded(with outcomes: some Collection<RefreshOutcome>, isRequested: Bool) -> SensoryFeedback? {
    if outcomes.contains(where: \.hasFailed) { return .error }
    guard isRequested || outcomes.contains(where: { $0 != .gateClosed }) else { return nil }

    return .impact(weight: .medium)
  }
}

// MARK: - RefreshHaptic

/// The haptic a refresh run ended with, or `nil` when it plays none. Each run's value is new, so
/// the same haptic plays again on the next run.
struct RefreshHaptic: Equatable {
  private let run: UUID = .init()
  let feedback: SensoryFeedback?
}

// MARK: - EffectsShell

extension EffectsShell {
  /// Runs the shell, then hands how the run ended to `status`, whose refresh haptic the tabs
  /// play: `isRequested` for a refresh the player asked for, such as pull to refresh.
  func run(isRequested: Bool, reportingTo status: AppStatus) async {
    let result = await run()
    status.refreshHaptic = RefreshHaptic(feedback: Haptic.refreshEnded(
      with: result.outcomes.values,
      isRequested: isRequested))
  }
}

// MARK: - RefreshOutcome

extension RefreshOutcome {
  /// Whether the feed's request failed.
  fileprivate var hasFailed: Bool {
    if case .fetched(.failed) = self { true } else { false }
  }
}
