//
//  WidgetAccessibilityTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore
@testable import IkaDesign

/// A widget's item on now reads its time left to VoiceOver, as the value
/// beside its sentence.
struct WidgetAccessibilityTests {
  static let rotation: Rotation = .init(
    mode: .battle(.x),
    startTime: date("2026-10-20T16:00:00Z"),
    endTime: date("2026-10-20T18:00:00Z"),
    setting: .init(rule: RuleID("VnNSdWxlLTE="), stages: [StageID("VnNTdGFnZS0x"), StageID("VnNTdGFnZS0y")]))

  static let sentence = "X Battle: Splat Zones on Scorch Gorge and Eeltail Alley, from 16:00 to 18:00."

  static func writer() throws -> SentenceWriter {
    try SentenceWriter(
      terms: GameTerms(language: .enUS, refreshed: nil, feed: TermTable()),
      timeZone: #require(TimeZone(identifier: "UTC")),
      hourCycle: .zeroToTwentyThree)
  }

  @Test
  func `A current Rotation reads its sentence, then counts down to its end as the value`() throws {
    let accessibility: WidgetAccessibility = try .init(Self.rotation, writer: Self.writer(), isCurrent: true)

    #expect(accessibility.label == Self.sentence)
    #expect(accessibility.countdown == Self.rotation.startTime ... Self.rotation.endTime)
  }

  @Test
  func `A later Rotation reads its sentence with no value`() throws {
    let accessibility: WidgetAccessibility = try .init(Self.rotation, writer: Self.writer(), isCurrent: false)

    #expect(accessibility.label == Self.sentence)
    #expect(accessibility.countdown == nil)
  }

  @Test
  func `A current Shift counts down to its end as the value`() throws {
    let shift: Shift = .init(
      kind: .regular,
      startTime: date("2026-10-20T16:00:00Z"),
      endTime: date("2026-10-22T08:00:00Z"),
      stage: StageID("Q29vcFN0YWdlLTE="),
      weapons: [.random, .random, .random, .random],
      kingSalmonid: nil)

    let accessibility: WidgetAccessibility = try .init(shift, writer: Self.writer(), isCurrent: true)

    #expect(accessibility.label == "Salmon Run: Spawning Grounds with Random, Random, Random, and Random, "
      + "from Tuesday 16:00 to Thursday 08:00.")
    #expect(accessibility.countdown == shift.startTime ... shift.endTime)
  }

  @Test
  func `What a Battle Mode has on reads its Rotation with the countdown, or its pause with none, then a note`() throws {
    let writer: SentenceWriter = try Self.writer()

    let running: WidgetAccessibility = .init(.item(Self.rotation), of: .x, writer: writer, note: "Stale.")
    let paused: WidgetAccessibility = .init(.paused(returnTime: date("2026-11-02T00:00:00Z")), of: .x, writer: writer)

    #expect(running.label == "\(Self.sentence) Stale.")
    #expect(running.countdown == Self.rotation.startTime ... Self.rotation.endTime)
    #expect(paused.label == "X Battle: paused during the Splatfest until Monday 00:00.")
    #expect(paused.countdown == nil)
  }
}
