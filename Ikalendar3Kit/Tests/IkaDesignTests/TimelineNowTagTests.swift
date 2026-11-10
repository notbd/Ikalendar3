//
//  TimelineNowTagTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import SwiftUI
import Testing
@testable import IkaDesign

// MARK: - TimelineNowTagTests

/// Pins how Timeline's "Now" tag fits its slot: from the first accessibility text size the
/// countdown wraps within the width offered instead of running past it, in the longest wordings.
@MainActor
struct TimelineNowTagTests {
  @Test(arguments: [GameLanguage.frFR, .ruRU])
  func `At an accessibility size the countdown wraps within a narrow slot`(language: GameLanguage) throws {
    // Narrower than "encore" or "осталось" with a two-digit hour countdown at any text size: the
    // Mac test host does not scale fonts with the text size, so the slot stands in for it.
    let width: CGFloat = 60
    let renderer: ImageRenderer = .init(content: TimelineNowTag(
      timeLeft: .seconds(39 * 3600 + 59 * 60 + 59),
      color: .neutral,
      language: language,
      now: Date(timeIntervalSince1970: 0))
      .environment(\.dynamicTypeSize, .accessibility5))
    renderer.proposedSize = ProposedViewSize(width: width, height: nil)
    renderer.scale = 1

    let image = try #require(renderer.cgImage)

    #expect(CGFloat(image.width) <= width, "\(image.width) x \(image.height)")
  }
}
