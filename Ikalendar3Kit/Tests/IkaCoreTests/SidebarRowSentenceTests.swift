//
//  SidebarRowSentenceTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

/// A sidebar row reads as one VoiceOver element: the sentence of its current item, or of why none
/// is on.
struct SidebarRowSentenceTests {
  @Test
  func `An event row reads its item's sentence, with the time left while it runs`() async throws {
    let snapshot = try await Snapshot.schedules(.eggstraWork)
    let instant = date("2026-08-29T12:00:00Z")
    let writer: SentenceWriter = SentenceWriterTests.writer()
    let sidebar = try #require(snapshot.sidebar(at: instant))
    let eggstraWork = try #require(snapshot.schedules?.content.eggstraWork.first)

    let sentence = try writer.sentence(for: #require(sidebar.groups.last?.rows.last), at: instant)

    #expect(sentence == writer.sentence(for: eggstraWork, at: instant))
    #expect(sentence.hasPrefix("Eggstra Work: "))
    #expect(sentence.hasSuffix(", 36 hours left."))
  }

  @Test
  func `Tricolor Turf War before the midterm time reads when it runs, with no time left`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestFirstHalf)
    let instant = date("2026-10-31T12:00:00Z")
    let writer: SentenceWriter = SentenceWriterTests.writer()
    let tricolorTurfWar = try #require(snapshot.splatfest?.tricolorTurfWar)

    let sentence = writer.sentence(for: .tricolorTurfWar(.next(tricolorTurfWar)), at: instant)

    #expect(sentence == writer.sentence(for: tricolorTurfWar, at: instant))
    #expect(sentence.hasPrefix("Splatfest Battle: Tricolor on "))
    #expect(!sentence.contains("left"))
  }

  @Test(arguments: [
    (
      SidebarRow.splatfestBattle(.pro, .nothingCurrent),
      "Splatfest Battle (Pro): what is on now is not in the published Schedule."),
    (.challenge(nil), "Challenges: none announced yet."),
  ])
  func `A row with nothing on reads why, naming its Mode`(_ row: SidebarRow, _ expected: String) {
    #expect(SentenceWriterTests.writer().sentence(for: row, at: TestData.epoch) == expected)
  }
}
