//
//  SidebarRowContentTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore
@testable import IkaDesign

/// Pins what every Style's sidebar row shows on the recorded feeds: the Mode's icon in a ring of
/// the share passed, its name, and its current item with the time left, or why none is on.
/// Times are written in UTC on a 24-hour clock.
struct SidebarRowContentTests {
  @Test
  func `A running Battle Mode's row shows its Rule and time left around a ring in its Mode colour`() async throws {
    let instant = date("2026-10-20T13:30:00Z")
    let (row, writer) = try await row(.mode(.battle(.anarchySeries)), in: .normalDay, at: instant)

    let content: SidebarRowContent = .init(row: row, writer: writer, format: format, now: instant)

    #expect(content.icon == .anarchy)
    #expect(content.color == .anarchy)
    #expect(content.name == "Anarchy Battle (Series)")
    #expect(content.summary == "Rainmaker · 30 minutes left")
    #expect(content.progress == .init(timeLeft: .seconds(1800), sharePassed: 0.75))
    #expect(!content.isDimmed)
    #expect(content.accessibilityLabel == writer.sentence(for: row, at: instant))
    #expect(content.accessibilityValue == nil)
  }

  @Test
  func `A paused Battle Mode's row is dimmed, with an empty ring and its return time`() async throws {
    let instant = date("2026-11-01T05:23:00Z")
    let (row, writer) = try await row(.mode(.battle(.x)), in: .splatfestSecondHalf, at: instant)

    let content: SidebarRowContent = .init(row: row, writer: writer, format: format, now: instant)

    #expect(content.summary == "Returns \(format.time(date("2026-11-02T00:00:00Z"), relativeTo: instant))")
    #expect(content.progress == nil)
    #expect(content.isDimmed)
  }

  @Test
  func `The Challenge row names Challenges, shows when the next window starts and reads it as its value`()
    async throws
  {
    let instant = date("2026-10-23T01:00:00Z")
    let (row, writer) = try await row(.challenge, in: .normalDay, at: instant)
    guard case .challenge(.next(let window)?) = row else {
      Issue.record("A Challenge window comes next at 02:00")
      return
    }

    let content: SidebarRowContent = .init(row: row, writer: writer, format: format, now: instant)

    #expect(content.icon == .challenge)
    #expect(content.name == "Challenges")
    #expect(content.summary == "\(writer.terms.challenge(window.challenge.id).name) · Starts 02:00")
    #expect(content.progress == nil)
    #expect(content.accessibilityLabel == "Challenges")
    #expect(content.accessibilityValue == writer.sentence(for: window, at: instant))
  }

  @Test
  func `A Big Run on now shows its icon and colour on Salmon Run's row`() async throws {
    let instant = date("2026-09-13T00:00:00Z")
    let (row, writer) = try await row(.mode(.salmonRun), in: .bigRun, at: instant)

    let content: SidebarRowContent = .init(row: row, writer: writer, format: format, now: instant)

    #expect(content.name == "Salmon Run")
    #expect(content.icon == .bigRun)
    #expect(content.color == .bigRun)
    #expect(content.summary.hasSuffix(" · 24 hours left"))
  }

  @Test
  func `The Splatfest's rows take no Mode colour and name their forms short, under the Splatfest group`()
    async throws
  {
    let instant = date("2026-11-01T05:23:00Z")
    let snapshot = try await snapshot(.splatfestSecondHalf)
    let writer = writer(snapshot)
    let rows = try #require(snapshot.sidebar(at: instant)?.groups.first?.rows)

    let contents: [SidebarRowContent] = rows.map { .init(row: $0, writer: writer, format: format, now: instant) }

    #expect(contents.map(\.name) == ["Splatfest", "Open", "Pro", "Tricolor"])
    #expect(contents.allSatisfy { $0.color == nil && $0.icon == .splatfestBattle && !$0.isDimmed })
    #expect(contents.allSatisfy { $0.summary.hasSuffix(" left") })
  }

  @Test
  func `Tricolor Turf War before the midterm time is dimmed and shows when it starts`() async throws {
    let instant = date("2026-10-31T12:00:00Z")
    let (row, writer) = try await row(.tricolorTurfWar, in: .splatfestFirstHalf, at: instant)

    let content: SidebarRowContent = .init(row: row, writer: writer, format: format, now: instant)

    #expect(content.summary == "Starts \(format.time(date("2026-11-01T00:00:00Z"), relativeTo: instant))")
    #expect(content.progress == nil)
    #expect(content.isDimmed)
  }

  @Test
  func `With no Challenge announced the row says so`() async throws {
    let instant = date("2026-10-31T00:00:00Z")
    let (row, writer) = try await row(.challenge, in: .normalDay, at: instant)

    let content: SidebarRowContent = .init(row: row, writer: writer, format: format, now: instant)

    #expect(content.summary == "None announced yet")
    #expect(content.accessibilityLabel == "Challenges")
    #expect(content.accessibilityValue == "Challenges: none announced yet.")
  }

  // MARK: Helpers

  private let format: ScheduleFormat = .init(language: .enUS, timeZone: .gmt, hourCycle: .zeroToTwentyThree)

  private func snapshot(_ fixture: Fixture) async throws -> Snapshot {
    try await Snapshot(schedules: Fetched(content: ScheduleFeed.decode(from: fixture.data()), fetchTime: .distantPast))
  }

  private func writer(_ snapshot: Snapshot) -> SentenceWriter {
    SentenceWriter(terms: snapshot.terms(in: .enUS), timeZone: .gmt, hourCycle: .zeroToTwentyThree)
  }

  /// The sidebar row of `item` on `fixture` at `instant`, and a writer of the feed's terms.
  private func row(
    _ item: SidebarItem,
    in fixture: Fixture,
    at instant: Date)
    async throws -> (SidebarRow, SentenceWriter)
  {
    let snapshot = try await snapshot(fixture)
    let sidebar = try #require(snapshot.sidebar(at: instant))
    let row = try #require(sidebar.groups.flatMap(\.rows).first { $0.item == item })
    return (row, writer(snapshot))
  }
}
