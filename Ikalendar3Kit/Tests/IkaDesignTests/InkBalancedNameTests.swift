//
//  InkBalancedNameTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaDesign

/// Pins that a name set on two lines, a Rule's in a later panel's column or a Mode's in a narrow
/// heading, breaks only between words.
struct InkBalancedNameTests {
  @Test(arguments: [
    ("Turf War", "Turf\nWar"),
    ("Splat Zones", "Splat\nZones"),
    ("Tower Control", "Tower\nControl"),
    ("Clam Blitz", "Clam\nBlitz"),
  ])
  func `A name of two words breaks between them`(name: String, lines: String) {
    #expect(InkBalancedName.balanced(name) == lines)
  }

  @Test
  func `A name of one word stays whole, so it can only shrink`() {
    #expect(InkBalancedName.balanced("Rainmaker") == "Rainmaker")
  }

  @Test
  func `A longer name breaks at the space nearest its middle`() {
    #expect(InkBalancedName.balanced("Guerre de territoire") == "Guerre de\nterritoire")
  }
}
