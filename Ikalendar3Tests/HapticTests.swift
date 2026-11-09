//
//  HapticTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import Testing
@testable import Ikalendar3

// MARK: - HapticTests

/// ikalendar 2's event-to-haptic table, for the events the app has so far.
struct HapticTests {
  /// A refresh's outcomes: one feed's, the other two feeds kept behind the gate.
  nonisolated static func outcomes(_ outcome: RefreshOutcome) -> [RefreshOutcome] {
    [outcome, .gateClosed, .gateClosed]
  }

  /// ikalendar 2 played the haptic of a load on pull to refresh and when a
  /// load ran; an activation the gate keeps entirely from the network loads nothing.
  @Test(arguments: [
    (outcomes(.gateClosed), false, SensoryFeedback?.none),
    (outcomes(.fetched(.confirmed)), false, .impact(weight: .medium)),
    (outcomes(.fetched(.updated)), false, .impact(weight: .medium)),
    (outcomes(.fetched(.failed(.noAnswer))), false, .error),
    (outcomes(.gateClosed), true, .impact(weight: .medium)),
    (outcomes(.fetched(.failed(.status(500)))), true, .error),
  ])
  func `A refresh plays its haptic only when the player asked for it or a request left the gate`(
    outcomes: [RefreshOutcome],
    isRequested: Bool,
    feedback: SensoryFeedback?)
  {
    #expect(Haptic.refreshEnded(with: outcomes, isRequested: isRequested) == feedback)
  }

  @Test
  func `A tab or Mode switch plays a soft impact`() {
    #expect(Haptic.modeSwitch == .impact(flexibility: .soft))
  }

  @Test
  func `Showing Settings plays a rigid impact and dismissing it plays none`() {
    #expect(Haptic.settingsPresentationChanged(to: true) == .impact(flexibility: .rigid))
    #expect(Haptic.settingsPresentationChanged(to: false) == nil)
  }
}
