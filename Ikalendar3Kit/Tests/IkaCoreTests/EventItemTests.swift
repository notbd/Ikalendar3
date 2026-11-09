//
//  EventItemTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct EventItemTests {
  /// A fixture at an instant and the events it publishes there, as kind, start and end.
  struct EventCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let events: [Event]

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  /// An event item reduced to what the test checks.
  struct Event: Equatable {
    let kind: String
    let start: String
    let end: String
  }

  @Test(arguments: [
    EventCase(fixture: .normalDay, instant: "2026-10-20T12:00:00Z", events: [
      Event(kind: "challenge", start: "2026-10-23T02:00:00Z", end: "2026-10-23T04:00:00Z"),
    ]),
    EventCase(fixture: .splatfestAnnounced, instant: "2026-10-30T12:00:00Z", events: [
      Event(kind: "challenge", start: "2026-10-30T14:00:00Z", end: "2026-10-30T16:00:00Z"),
      Event(kind: "splatfest", start: "2026-10-31T00:00:00Z", end: "2026-11-02T00:00:00Z"),
    ]),
    EventCase(fixture: .splatfestFirstHalf, instant: "2026-10-31T12:00:00Z", events: [
      Event(kind: "challenge", start: "2026-11-10T02:00:00Z", end: "2026-11-10T04:00:00Z"),
      Event(kind: "splatfest", start: "2026-10-31T00:00:00Z", end: "2026-11-02T00:00:00Z"),
    ]),
    EventCase(fixture: .splatfestSecondHalf, instant: "2026-11-01T05:23:00Z", events: [
      Event(kind: "challenge", start: "2026-11-10T02:00:00Z", end: "2026-11-10T04:00:00Z"),
      Event(kind: "splatfest", start: "2026-10-31T00:00:00Z", end: "2026-11-02T00:00:00Z"),
    ]),
    EventCase(fixture: .splatfestEnd, instant: "2026-08-23T20:00:00Z", events: [
      Event(kind: "challenge", start: "2026-08-28T02:00:00Z", end: "2026-08-28T04:00:00Z"),
      Event(kind: "splatfest", start: "2026-08-22T00:00:00Z", end: "2026-08-24T00:00:00Z"),
      Event(kind: "eggstraWork", start: "2026-08-29T00:00:00Z", end: "2026-08-31T00:00:00Z"),
    ]),
    EventCase(fixture: .bigRun, instant: "2026-09-07T12:00:00Z", events: [
      Event(kind: "challenge", start: "2026-09-08T02:00:00Z", end: "2026-09-08T04:00:00Z"),
      Event(kind: "bigRun", start: "2026-09-12T00:00:00Z", end: "2026-09-14T00:00:00Z"),
    ]),
    EventCase(fixture: .eggstraWork, instant: "2026-08-28T12:00:00Z", events: [
      Event(kind: "challenge", start: "2026-08-28T14:00:00Z", end: "2026-08-28T16:00:00Z"),
      Event(kind: "eggstraWork", start: "2026-08-29T00:00:00Z", end: "2026-08-31T00:00:00Z"),
    ]),
  ])
  func `The event items list exactly the events each fixture publishes`(_ eventCase: EventCase) async throws {
    try await expectEvents(of: eventCase)
  }

  @Test(arguments: [
    // In a Challenge window, during the Big Run and during the Eggstra Work: each is the running one.
    EventCase(fixture: .bigRun, instant: "2026-09-08T03:00:00Z", events: [
      Event(kind: "challenge", start: "2026-09-08T02:00:00Z", end: "2026-09-08T04:00:00Z"),
      Event(kind: "bigRun", start: "2026-09-12T00:00:00Z", end: "2026-09-14T00:00:00Z"),
    ]),
    EventCase(fixture: .bigRun, instant: "2026-09-13T12:00:00Z", events: [
      Event(kind: "challenge", start: "2026-09-17T02:00:00Z", end: "2026-09-17T04:00:00Z"),
      Event(kind: "bigRun", start: "2026-09-12T00:00:00Z", end: "2026-09-14T00:00:00Z"),
    ]),
    EventCase(fixture: .eggstraWork, instant: "2026-08-29T12:00:00Z", events: [
      Event(kind: "challenge", start: "2026-08-30T00:00:00Z", end: "2026-08-30T02:00:00Z"),
      Event(kind: "eggstraWork", start: "2026-08-29T00:00:00Z", end: "2026-08-31T00:00:00Z"),
    ]),
    // Every event over: the Big Run ended, the last Challenge window closed.
    EventCase(fixture: .bigRun, instant: "2026-09-18T00:00:00Z", events: []),
    // The Splatfest is over and its Challenges are past.
    EventCase(fixture: .splatfestSecondHalf, instant: "2026-11-20T00:00:00Z", events: []),
  ])
  func `An event that runs is listed until it ends, then the next one or none`(_ eventCase: EventCase) async throws {
    try await expectEvents(of: eventCase)
  }

  @Test
  func `No event items exist before the schedules feed's first good response`() {
    #expect(Snapshot().eventItems(at: TestData.epoch) == nil)
  }

  private func expectEvents(of eventCase: EventCase) async throws {
    let snapshot = try await Snapshot.schedules(eventCase.fixture)

    let items = try #require(snapshot.eventItems(at: date(eventCase.instant)))

    #expect(items.map(Self.event) == eventCase.events)
  }

  static private func event(_ item: EventItem) -> Event {
    let kind =
      switch item {
        case .challenge: "challenge"
        case .splatfest: "splatfest"
        case .bigRun(let shift): shift.kind == .bigRun ? "bigRun" : "wrong kind"
        case .eggstraWork(let shift): shift.kind == .eggstraWork ? "eggstraWork" : "wrong kind"
      }
    return Event(kind: kind, start: item.startTime.ISO8601Format(), end: item.endTime.ISO8601Format())
  }
}
