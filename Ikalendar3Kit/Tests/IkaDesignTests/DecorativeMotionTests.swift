//
//  DecorativeMotionTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaDesign

/// Pins the Reduce Motion rule: every decorative motion plays in full by default and turns into a
/// still or a cross-fade form under Reduce Motion, as the spec's accessibility rules list them.
struct DecorativeMotionTests {
  /// Every named decorative motion and its Reduce Motion form, from the spec's accessibility rules.
  static private let reducedForms: [DecorativeMotion: MotionForm] = [
    .stampTilt: .still,
    .stampDock: .crossFade,
    .squashBounce: .still,
    .iconNudge: .still,
    .buttonPulse: .still,
    .periodicPulse: .crossFade,
    .listReflow: .still,
    .countdownRoll: .crossFade,
    // The change happens at once.
    .currentIconGrow: .still,
  ]

  @Test
  func `The list names every decorative motion`() {
    #expect(Set(DecorativeMotion.allCases) == Set(Self.reducedForms.keys))
  }

  @Test(arguments: DecorativeMotion.allCases)
  func `Every decorative motion plays in full without Reduce Motion`(motion: DecorativeMotion) {
    #expect(motion.form(reduceMotion: false) == .full)
  }

  @Test(arguments: DecorativeMotion.allCases)
  func `Every decorative motion is still or a cross-fade under Reduce Motion`(motion: DecorativeMotion) {
    let form: MotionForm = motion.form(reduceMotion: true)

    #expect(form == .still || form == .crossFade)
    #expect(form == Self.reducedForms[motion])
  }
}
