//
//  InkRuleNameTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaDesign

/// Pins that a Rule's name in a later panel's column breaks only between words.
struct InkRuleNameTests {
  @Test(arguments: [
    ("Turf War", "Turf\nWar"),
    ("Splat Zones", "Splat\nZones"),
    ("Tower Control", "Tower\nControl"),
    ("Clam Blitz", "Clam\nBlitz"),
  ])
  func `A name of two words breaks between them`(name: String, lines: String) {
    #expect(InkRuleName.balanced(name) == lines)
  }

  @Test
  func `A name of one word stays whole, so it can only shrink`() {
    #expect(InkRuleName.balanced("Rainmaker") == "Rainmaker")
  }

  @Test
  func `A longer name breaks at the space nearest its middle`() {
    #expect(InkRuleName.balanced("Guerre de territoire") == "Guerre de\nterritoire")
  }
}
