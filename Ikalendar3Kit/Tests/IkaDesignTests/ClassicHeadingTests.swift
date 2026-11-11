//
//  ClassicHeadingTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaDesign

/// Pins how Classic heads a screen: the Mode's name over the list with its form under it, and the
/// full name in the navigation bar.
struct ClassicHeadingTests {
  @Test
  func `An Anarchy Battle form goes under the name, and the bar keeps the full name`() {
    let heading: ClassicHeading = .init(.battle(.anarchySeries), in: .enUS)

    #expect(heading.name == "Anarchy Battle")
    #expect(heading.form == "Series")
    #expect(heading.title == "Anarchy Battle (Series)")
  }

  @Test
  func `A Mode with one form has no form under its name`() {
    let heading: ClassicHeading = .init(.battle(.regular), in: .enUS)

    #expect(heading.name == "Regular Battle")
    #expect(heading.form == nil)
    #expect(heading.title == "Regular Battle")
  }

  @Test
  func `Splatfest Battle's form goes under its name`() {
    let heading: ClassicHeading = .init(splatfestBattle: .pro, in: .enUS)

    #expect(heading.name == "Splatfest Battle")
    #expect(heading.form == "Pro")
    #expect(heading.title == "Splatfest Battle (Pro)")
  }
}
