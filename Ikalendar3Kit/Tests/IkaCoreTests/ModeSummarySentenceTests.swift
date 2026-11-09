//
//  ModeSummarySentenceTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

/// A Mode summary's row reads as one VoiceOver element: the sentence of what it summarizes.
struct ModeSummarySentenceTests {
  @Test
  func `A running Rotation's summary reads the Rotation's sentence with its time left`() {
    let summary: ModeSummary = .battle(.x, .running(.init(
      item: SentenceWriterTests.rotation,
      progress: .init(timeLeft: .seconds(80 * 60), sharePassed: 1.0 / 3))))

    let sentence = SentenceWriterTests.writer().sentence(for: summary, at: TestData.instant(hours: 16 + 40.0 / 60))

    #expect(sentence == "X Battle: Splat Zones on Scorch Gorge and Eeltail Alley, "
      + "from 8:00\u{202F}AM to 10:00\u{202F}AM, 1 hour 20 minutes left.")
  }

  @Test
  func `A running Shift's summary reads the Shift's sentence with its time left`() {
    let shift: Shift = .init(
      kind: .bigRun,
      startTime: TestData.instant(hours: 16),
      endTime: TestData.instant(hours: 64),
      stage: StageID("VnNTdGFnZS0x"),
      weapons: [.random, .random, .random, .random],
      kingSalmonid: KingSalmonidID("Q29vcEVuZW15LTIz"))
    let summary: ModeSummary = .salmonRun(.running(.init(
      item: shift,
      progress: .init(timeLeft: .seconds(2 * 3600), sharePassed: 46.0 / 48))))

    let sentence = SentenceWriterTests.writer().sentence(for: summary, at: TestData.instant(hours: 62))

    #expect(sentence == "Big Run: Scorch Gorge with Random, Random, Random, and Random, "
      + "from Thursday 8:00\u{202F}AM to Saturday 8:00\u{202F}AM, 2 hours left.")
  }

  @Test
  func `A paused Battle Mode's summary reads when the Battle Mode comes back`() {
    let summary: ModeSummary = .battle(.anarchySeries, .paused(returnTime: TestData.instant(hours: 4 * 24 + 17)))

    let sentence = SentenceWriterTests.writer().sentence(for: summary, at: TestData.instant(hours: 4 * 24))

    #expect(sentence == "Anarchy Battle (Series): paused during the Splatfest until Monday 9:00\u{202F}AM.")
  }

  /// It reads as Siri answers the same question.
  @Test(arguments: [
    (ModeSummary.battle(.regular, .nothingCurrent), "Regular Battle: what is on now is not in the published Schedule."),
    (ModeSummary.salmonRun(.nothingCurrent), "Salmon Run: what is on now is not in the published Schedule."),
  ])
  func `A summary with nothing current reads that the published Schedule has nothing now`(
    _ summary: ModeSummary,
    _ expected: String)
  {
    #expect(SentenceWriterTests.writer().sentence(for: summary, at: TestData.epoch) == expected)
  }

  @Test(arguments: GameLanguage.allCases)
  func `A summary with nothing current reads in every text set`(_ language: GameLanguage) {
    let sentence = SentenceWriterTests.writer(language).sentence(for: .salmonRun(.nothingCurrent), at: TestData.epoch)

    #expect(!sentence.contains("answer."))
    #expect(sentence.contains(ModeLabel.salmonRun.text(in: language)))
  }
}
