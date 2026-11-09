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
  @Test(arguments: [
    (RefreshStatus.loading, RefreshStatus.loaded, SensoryFeedback?.some(.impact(weight: .medium))),
    (.loading, .failed, .error),
    (.loaded, .loading, nil),
    (.failed, .loading, nil),
  ])
  func `A refresh that ends plays ikalendar 2's haptic and one that starts plays none`(
    old: RefreshStatus,
    new: RefreshStatus,
    feedback: SensoryFeedback?)
  {
    #expect(Haptic.refreshChanged(from: old, to: new) == feedback)
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
