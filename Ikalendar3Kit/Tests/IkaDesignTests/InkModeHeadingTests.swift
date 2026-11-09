//
//  InkModeHeadingTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaDesign

/// Pins how Ink names a Mode over its list: the Mode's name, with Anarchy Battle's form on a tag.
struct InkModeHeadingTests {
  @Test
  func `Anarchy Battle's forms show the Mode's name over the form`() {
    #expect(InkModeHeading(.battle(.anarchySeries)) == InkModeHeading(name: .anarchyBattle, form: .series))
    #expect(InkModeHeading(.battle(.anarchyOpen)) == InkModeHeading(name: .anarchyBattle, form: .open))
  }

  @Test
  func `Modes with one form show their name alone`() {
    #expect(InkModeHeading(.battle(.regular)) == InkModeHeading(name: .regularBattle, form: nil))
    #expect(InkModeHeading(.battle(.x)) == InkModeHeading(name: .xBattle, form: nil))
    #expect(InkModeHeading(.salmonRun) == InkModeHeading(name: .salmonRun, form: nil))
  }
}
