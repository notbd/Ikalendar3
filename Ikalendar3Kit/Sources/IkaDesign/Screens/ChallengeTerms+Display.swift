//
//  ChallengeTerms+Display.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore

extension ChallengeTerms {
  /// The description on one line: the feed's `<br />` only breaks it to fit the game's panel,
  /// often mid-sentence.
  var displayDescription: String {
    description.replacing("<br />", with: " ")
  }

  /// The rules text with the feed's `<br />` marks as line breaks.
  var displayRulesText: String {
    rulesText.replacing("<br />", with: "\n")
  }
}
