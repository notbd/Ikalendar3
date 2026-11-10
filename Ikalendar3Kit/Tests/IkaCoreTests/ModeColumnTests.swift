//
//  ModeColumnTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

/// The iPad's columns on the recorded days: one per Mode, or the Splatfest's while it runs.
///
/// The 2026-10-31 Splatfest runs from 2026-10-31 00:00 UTC for two days; the 2026-08-23 one ends
/// on 2026-08-24 00:00 UTC.
struct ModeColumnTests {
  /// A fixture at an instant, and whether the Splatfest's columns show then.
  struct ColumnSetCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let isSplatfest: Bool

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  static let modeColumns: [ModeColumn] = [.regularBattle, .anarchy, .xBattle, .salmonRun]
  static let splatfestColumns: [ModeColumn] = [.splatfestBattle(.open), .splatfestBattle(.pro), .salmonRun]

  @Test(arguments: [
    ColumnSetCase(fixture: .normalDay, instant: "2026-10-20T13:00:00Z", isSplatfest: false),
    ColumnSetCase(fixture: .bigRun, instant: "2026-09-07T12:00:00Z", isSplatfest: false),
    // Announced: not yet. The Splatfest's columns come on time with no new fetch.
    ColumnSetCase(fixture: .splatfestAnnounced, instant: "2026-10-30T23:59:59Z", isSplatfest: false),
    ColumnSetCase(fixture: .splatfestAnnounced, instant: "2026-10-31T00:00:00Z", isSplatfest: true),
    // First half and second half.
    ColumnSetCase(fixture: .splatfestFirstHalf, instant: "2026-10-31T12:00:00Z", isSplatfest: true),
    ColumnSetCase(fixture: .splatfestSecondHalf, instant: "2026-11-01T05:23:00Z", isSplatfest: true),
    // Its last second, then over.
    ColumnSetCase(fixture: .splatfestEnd, instant: "2026-08-23T23:59:59Z", isSplatfest: true),
    ColumnSetCase(fixture: .splatfestEnd, instant: "2026-08-24T00:00:00Z", isSplatfest: false),
  ])
  func `The columns are one per Mode, or the Splatfest's two forms and Salmon Run while it runs`(
    _ columnSet: ColumnSetCase)
    async throws
  {
    let snapshot = try await Snapshot.schedules(columnSet.fixture)

    let columns = snapshot.columns(at: date(columnSet.instant))

    #expect(columns == (columnSet.isSplatfest ? Self.splatfestColumns : Self.modeColumns))
  }

  @Test
  func `The four Mode columns show before the schedules feed's first good response`() {
    #expect(Snapshot().columns(at: TestData.epoch) == Self.modeColumns)
  }

  @Test
  func `Only the Anarchy column's header opens a menu, the Series and Open one`() {
    let columns = Self.modeColumns + Self.splatfestColumns

    #expect(columns.map(\.menu) == [nil, .anarchy, nil, nil, nil, nil, nil])
  }
}
