//
//  ChallengeTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaCore
@testable import IkaDesign

struct ChallengeTextTests {
  private let terms: ChallengeTerms = .init(
    name: "Dualies at Ten Paces",
    description: "Enter a battlefield filled with slippery<br />customers in this all-dualies war!",
    rulesText: "Stick and move!<br /><br />・ Players can only choose dualies.")

  @Test
  func `A Challenge description reads on one line`() {
    #expect(terms.displayDescription == "Enter a battlefield filled with slippery customers in this all-dualies war!")
  }

  @Test
  func `A Challenge's rules text breaks its lines where the feed marks them`() {
    #expect(terms.displayRulesText == "Stick and move!\n\n・ Players can only choose dualies.")
  }
}
