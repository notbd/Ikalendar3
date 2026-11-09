//
//  TrackingContentTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - TrackingContentTests

struct TrackingContentTests {
  @Test(arguments: [
    (Fixture.normalDay, "2026-10-20T12:00:00Z"),
    (.splatfestAnnounced, "2026-10-30T22:00:00Z"),
    (.splatfestFirstHalf, "2026-10-31T12:00:00Z"),
    (.splatfestSecondHalf, "2026-11-01T05:23:00Z"),
    (.splatfestEnd, "2026-08-23T20:00:00Z"),
    (.bigRun, "2026-09-09T12:00:00Z"),
    (.eggstraWork, "2026-08-28T12:00:00Z"),
  ])
  func `Every Mode's content encodes under ActivityKit's 4 KB and decodes back unchanged`(
    _ fixture: Fixture,
    _ instant: String)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: fixture.data())

    for mode in Mode.allCases {
      let content = feed.trackingContent(of: mode, at: date(instant))
      let encoded = try JSONEncoder().encode(content)
      #expect(encoded.count < 4096, "\(mode): \(encoded.count) bytes")
      #expect(try JSONDecoder().decode(TrackingContent.self, from: encoded) == content)
    }
  }

  @Test
  func `Tracking ends eight hours after it starts`() {
    #expect(TrackingContent.endDate(startedAt: date("2026-10-20T13:17:00Z")) == date("2026-10-20T21:17:00Z"))
  }

  @Test(arguments: BattleMode.allCases, ["2026-10-20T12:00:00Z", "2026-10-20T13:59:59Z"])
  func `Battle Tracking holds the Rotation on now and the next two, and goes stale when it ends`(
    _ mode: BattleMode,
    _ instant: String)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    let content = feed.trackingContent(of: .battle(mode), at: date(instant))

    let rotations = try #require(content.battleRotations)
    #expect(content.mode == .battle(mode))
    #expect(rotations.map(\.startTime) == everyTwoHours(from: "2026-10-20T12:00:00Z", count: 3))
    #expect(rotations.map(\.endTime) == everyTwoHours(from: "2026-10-20T14:00:00Z", count: 3))
    #expect(rotations.map(\.setting) == feed.rotations(for: .battle(mode)).prefix(3).map(\.setting))
    #expect(rotations.allSatisfy { !$0.isPaused })
    #expect(content.staleDate == date("2026-10-20T14:00:00Z"))
  }

  /// An instant on a fixture and the Shifts Salmon Run Tracking holds there.
  struct ShiftCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let shifts: [ShiftTimes]

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  /// A Shift by whether it is a Big Run and its real boundaries.
  struct ShiftTimes: Equatable, CustomStringConvertible {
    let isBigRun: Bool
    let start: Date
    let end: Date

    init(bigRun isBigRun: Bool = false, _ start: String, _ end: String) {
      self.isBigRun = isBigRun
      self.start = date(start)
      self.end = date(end)
    }

    init(_ shift: TrackedShift) {
      isBigRun = shift.isBigRun
      start = shift.startTime
      end = shift.endTime
    }

    var description: String { "\(isBigRun ? "Big Run" : "regular") \(start)..<\(end)" }
  }

  @Test(arguments: [
    // Regular Shifts of 40 hours.
    ShiftCase(fixture: .normalDay, instant: "2026-10-20T13:00:00Z", shifts: [
      .init("2026-10-19T00:00:00Z", "2026-10-20T16:00:00Z"),
      .init("2026-10-20T16:00:00Z", "2026-10-22T08:00:00Z"),
      .init("2026-10-22T08:00:00Z", "2026-10-24T00:00:00Z"),
    ]),
    // The 48-hour Big Run is the second of the next two, after a regular Shift cut to 32 hours.
    ShiftCase(fixture: .bigRun, instant: "2026-09-09T12:00:00Z", shifts: [
      .init("2026-09-09T00:00:00Z", "2026-09-10T16:00:00Z"),
      .init("2026-09-10T16:00:00Z", "2026-09-12T00:00:00Z"),
      .init(bigRun: true, "2026-09-12T00:00:00Z", "2026-09-14T00:00:00Z"),
    ]),
    // The last second before the Big Run: it is next, then the regular Shift after it.
    ShiftCase(fixture: .bigRun, instant: "2026-09-11T23:59:59Z", shifts: [
      .init("2026-09-10T16:00:00Z", "2026-09-12T00:00:00Z"),
      .init(bigRun: true, "2026-09-12T00:00:00Z", "2026-09-14T00:00:00Z"),
      .init("2026-09-14T00:00:00Z", "2026-09-15T16:00:00Z"),
    ]),
    // The Eggstra Work of 2026-08-29 00:00 runs beside these and is none of them.
    ShiftCase(fixture: .eggstraWork, instant: "2026-08-29T12:00:00Z", shifts: [
      .init("2026-08-28T08:00:00Z", "2026-08-30T00:00:00Z"),
      .init("2026-08-30T00:00:00Z", "2026-08-31T16:00:00Z"),
      .init("2026-08-31T16:00:00Z", "2026-09-02T08:00:00Z"),
    ]),
  ])
  func `Salmon Run Tracking holds the Shift on now and the next two, with real boundaries`(
    _ shiftCase: ShiftCase)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: shiftCase.fixture.data())

    let content = feed.trackingContent(of: .salmonRun, at: date(shiftCase.instant))

    let shifts = try #require(content.salmonRunShifts)
    #expect(content.mode == .salmonRun)
    #expect(shifts.map(ShiftTimes.init) == shiftCase.shifts)
    for shift in shifts {
      let published = try #require(feed.salmonRun.first { $0.startTime == shift.startTime })
      #expect(shift.stage == published.stage)
      #expect(shift.weapons == published.weapons)
    }
    #expect(content.staleDate == shiftCase.shifts.first?.end)
  }

  @Test(arguments: [false, true])
  func `With one later Rotation published, Tracking carries only it and then reports nothing later`(
    isStale: Bool)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    let content = feed.trackingContent(of: .battle(.regular), at: date("2026-10-21T09:00:00Z"))

    let rotations = try #require(content.battleRotations)
    #expect(rotations.map(\.startTime) == everyTwoHours(from: "2026-10-21T08:00:00Z", count: 2))
    let before: TrackingFrame<TrackedRotation> = .init(rotations, at: date("2026-10-21T09:00:00Z"), isStale: false)
    #expect(before.next == rotations[1])
    let after: TrackingFrame<TrackedRotation> = .init(rotations, at: date("2026-10-21T10:00:00Z"), isStale: isStale)
    #expect(after.current == rotations[1])
    #expect(after.next == nil)
    #expect(after.reminder != .scheduleOutOfDate)
  }

  @Test(arguments: BattleMode.allCases)
  func `Tracking started during a Splatfest shows the pause until the Battle Mode returns, then its Rotations`(
    _ mode: BattleMode)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.splatfestSecondHalf.data())

    let content = feed.trackingContent(of: .battle(mode), at: date("2026-11-01T05:23:00Z"))

    let rotations = try #require(content.battleRotations)
    try #require(rotations.count == 3)
    #expect(rotations[0].isPaused)
    #expect(rotations[0].startTime == date("2026-10-31T00:00:00Z"))
    #expect(rotations[0].endTime == date("2026-11-02T00:00:00Z"))
    #expect(rotations.dropFirst().map(\.startTime) == everyTwoHours(from: "2026-11-02T00:00:00Z", count: 2))
    #expect(rotations.dropFirst().allSatisfy { !$0.isPaused })
    #expect(content.staleDate == date("2026-11-02T00:00:00Z"))
    let frame: TrackingFrame<TrackedRotation> = .init(rotations, at: date("2026-11-01T05:23:00Z"), isStale: false)
    #expect(frame == TrackingFrame(current: rotations[0], next: rotations[1], reminder: nil))
  }

  @Test(arguments: BattleMode.allCases)
  func `Battle Tracking that runs into a Splatfest switches to the pause on its own at the Splatfest's start`(
    _ mode: BattleMode)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.splatfestAnnounced.data())

    let content = feed.trackingContent(of: .battle(mode), at: date("2026-10-30T22:30:00Z"))

    let rotations = try #require(content.battleRotations)
    try #require(rotations.count == 2)
    #expect(rotations[0].startTime == date("2026-10-30T22:00:00Z"))
    #expect(!rotations[0].isPaused)
    #expect(rotations[1].isPaused)
    #expect(rotations[1].startTime == date("2026-10-31T00:00:00Z"))
    #expect(rotations[1].endTime == date("2026-11-02T00:00:00Z"))
    let atStart: TrackingFrame<TrackedRotation> = .init(rotations, at: date("2026-10-31T00:00:00Z"), isStale: false)
    #expect(atStart == TrackingFrame(current: rotations[1], next: nil, reminder: nil))
  }

  @Test
  func `Without its Splatfest, a pause lasts from its first paused window to its last`() throws {
    let windows = [
      TestData.rotation(hours: 0 ..< 2),
      TestData.rotation(hours: 2 ..< 4, isPaused: true),
      TestData.rotation(hours: 4 ..< 6, isPaused: true),
      TestData.rotation(hours: 6 ..< 8),
    ]
    let feed: ScheduleFeed = TestData.feed(regularBattle: windows, failedSections: [.splatfest])

    for hour in [1.0, 3.0] {
      let content = feed.trackingContent(of: .battle(.regular), at: TestData.instant(hours: hour))
      let rotations = try #require(content.battleRotations)
      let pause = try #require(rotations.first { $0.isPaused })
      #expect(pause.startTime == TestData.instant(hours: 2))
      #expect(pause.endTime == TestData.instant(hours: 6))
      #expect(rotations.last == TrackedRotation(windows[3]))
    }
  }
}

extension TrackingContent {
  /// The Rotations of a Battle Mode's content, `nil` for Salmon Run's.
  var battleRotations: [TrackedRotation]? {
    if case .battle(_, let rotations) = self { rotations } else { nil }
  }

  /// The Shifts of Salmon Run's content, `nil` for a Battle Mode's.
  var salmonRunShifts: [TrackedShift]? {
    if case .salmonRun(let shifts) = self { shifts } else { nil }
  }
}
