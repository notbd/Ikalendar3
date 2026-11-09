//
//  SalmonRunLineupTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

struct SalmonRunLineupTests {
  /// A Shift by its kind and real boundaries.
  struct ShiftTimes: Equatable, CustomStringConvertible {
    let kind: Shift.Kind
    let start: Date
    let end: Date

    init(_ kind: Shift.Kind, _ start: String, _ end: String) {
      self.kind = kind
      self.start = date(start)
      self.end = date(end)
    }

    init(_ shift: Shift) {
      kind = shift.kind
      start = shift.startTime
      end = shift.endTime
    }

    var description: String { "\(kind) \(start)..<\(end)" }
  }

  /// An instant on a fixture and the Shifts Salmon Run's lineup holds.
  struct ShiftCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let current: ShiftTimes
    let next: ShiftTimes?
    let later: [String]

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  @Test(arguments: [
    // Inside a regular Shift of 40 hours.
    ShiftCase(
      fixture: .normalDay,
      instant: "2026-10-20T13:00:00Z",
      current: .init(.regular, "2026-10-19T00:00:00Z", "2026-10-20T16:00:00Z"),
      next: .init(.regular, "2026-10-20T16:00:00Z", "2026-10-22T08:00:00Z"),
      later: ["2026-10-22T08:00:00Z", "2026-10-24T00:00:00Z", "2026-10-25T16:00:00Z"]),
    // The last second of the regular Shift before a Big Run: the Big Run is next.
    ShiftCase(
      fixture: .bigRun,
      instant: "2026-09-11T23:59:59Z",
      current: .init(.regular, "2026-09-10T16:00:00Z", "2026-09-12T00:00:00Z"),
      next: .init(.bigRun, "2026-09-12T00:00:00Z", "2026-09-14T00:00:00Z"),
      later: ["2026-09-14T00:00:00Z"]),
    // A Big Run's first second, and its last: the regular Shift after it is next.
    ShiftCase(
      fixture: .bigRun,
      instant: "2026-09-12T00:00:00Z",
      current: .init(.bigRun, "2026-09-12T00:00:00Z", "2026-09-14T00:00:00Z"),
      next: .init(.regular, "2026-09-14T00:00:00Z", "2026-09-15T16:00:00Z"),
      later: []),
    ShiftCase(
      fixture: .bigRun,
      instant: "2026-09-13T23:59:59Z",
      current: .init(.bigRun, "2026-09-12T00:00:00Z", "2026-09-14T00:00:00Z"),
      next: .init(.regular, "2026-09-14T00:00:00Z", "2026-09-15T16:00:00Z"),
      later: []),
    // The 48 hours are over: the regular Shift after the Big Run is on, the last published.
    ShiftCase(
      fixture: .bigRun,
      instant: "2026-09-14T00:00:00Z",
      current: .init(.regular, "2026-09-14T00:00:00Z", "2026-09-15T16:00:00Z"),
      next: nil,
      later: []),
    // An Eggstra Work runs beside these regular Shifts and is neither of them.
    ShiftCase(
      fixture: .eggstraWork,
      instant: "2026-08-29T12:00:00Z",
      current: .init(.regular, "2026-08-28T08:00:00Z", "2026-08-30T00:00:00Z"),
      next: .init(.regular, "2026-08-30T00:00:00Z", "2026-08-31T16:00:00Z"),
      later: ["2026-08-31T16:00:00Z", "2026-09-02T08:00:00Z"]),
    // The Eggstra Work started before this regular Shift and still runs: the Shift is current.
    ShiftCase(
      fixture: .eggstraWork,
      instant: "2026-08-30T12:00:00Z",
      current: .init(.regular, "2026-08-30T00:00:00Z", "2026-08-31T16:00:00Z"),
      next: .init(.regular, "2026-08-31T16:00:00Z", "2026-09-02T08:00:00Z"),
      later: ["2026-09-02T08:00:00Z"]),
  ])
  func `Salmon Run holds the Shift on now, the next one and the rest, with real boundaries`(
    _ shift: ShiftCase)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: shift.fixture.data())

    let lineup = feed.salmonRunLineup(at: date(shift.instant))

    #expect(lineup.current.item.map(ShiftTimes.init) == shift.current)
    #expect(lineup.next.map(ShiftTimes.init) == shift.next)
    #expect(lineup.later.map(\.startTime) == shift.later.map(date))
  }

  @Test
  func `Salmon Run runs out when its last published Shift ends`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.bigRun.data())

    #expect(feed.salmonRunLineup(at: date("2026-09-15T16:00:00Z")) == Lineup(current: .ranOut, next: nil, later: []))
  }

  @Test
  func `A running Eggstra Work is reported on its own`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.eggstraWork.data())

    let lineup = feed.eggstraWorkLineup(at: date("2026-08-29T12:00:00Z"))

    #expect(lineup.current.item.map(ShiftTimes.init) == .init(
      .eggstraWork,
      "2026-08-29T00:00:00Z",
      "2026-08-31T00:00:00Z"))
    #expect(lineup.next == nil)
    #expect(lineup.later.isEmpty)
  }

  @Test
  func `An Eggstra Work is next before it starts, and none is announced after it ends`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.eggstraWork.data())

    let before = feed.eggstraWorkLineup(at: date("2026-08-28T23:59:59Z"))
    #expect(before.current == .gap)
    #expect(before.next?.startTime == date("2026-08-29T00:00:00Z"))

    let after = feed.eggstraWorkLineup(at: date("2026-08-31T00:00:00Z"))
    #expect(after == Lineup(current: .noneAnnounced, next: nil, later: []))
    #expect(feed.salmonRunLineup(at: date("2026-08-31T00:00:00Z")).current.item?.kind == .regular)
  }
}
