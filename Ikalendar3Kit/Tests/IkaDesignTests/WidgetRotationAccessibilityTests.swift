//
//  WidgetRotationAccessibilityTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore
@testable import IkaDesign

/// Council round 5, M2: a widget's current Rotation reads its time left to VoiceOver.
struct WidgetRotationAccessibilityTests {
  static let rotation: Rotation = .init(
    mode: .battle(.x),
    startTime: date("2026-10-20T16:00:00Z"),
    endTime: date("2026-10-20T18:00:00Z"),
    setting: .init(rule: RuleID("VnNSdWxlLTE="), stages: [StageID("VnNTdGFnZS0x"), StageID("VnNTdGFnZS0y")]))

  static func writer() throws -> SentenceWriter {
    try SentenceWriter(
      terms: GameTerms(language: .enUS, refreshed: nil, feed: TermTable()),
      timeZone: #require(TimeZone(identifier: "UTC")),
      hourCycle: .zeroToTwentyThree)
  }

  @Test
  func `A current Rotation reads its sentence, then counts down to its end as the value`() throws {
    let reading: WidgetRotationAccessibility = try .init(Self.rotation, writer: Self.writer(), isCurrent: true)

    #expect(reading.label == "X Battle: Splat Zones on Scorch Gorge and Eeltail Alley, from 16:00 to 18:00.")
    #expect(reading.countdown == Self.rotation.startTime ... Self.rotation.endTime)
  }

  @Test
  func `A later Rotation reads its sentence with no value`() throws {
    let reading: WidgetRotationAccessibility = try .init(Self.rotation, writer: Self.writer(), isCurrent: false)

    #expect(reading.label == "X Battle: Splat Zones on Scorch Gorge and Eeltail Alley, from 16:00 to 18:00.")
    #expect(reading.countdown == nil)
  }
}
