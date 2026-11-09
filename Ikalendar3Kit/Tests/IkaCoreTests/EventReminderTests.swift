//
//  EventReminderTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct EventReminderTests {
  /// A fixture at an instant and the reminders it calls for with every switch on, as kind and
  /// start, read off the payload.
  struct ReminderCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let reminders: [Reminder]

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  /// A reminder reduced to what the test checks.
  struct Reminder: Equatable {
    let kind: EventReminder.Kind
    let start: String

    init(_ kind: EventReminder.Kind, _ start: String) {
      self.kind = kind
      self.start = start
    }
  }

  /// Each published event still to start, the Challenges at their first window. Started events get
  /// none: the Eggstra Work day's and the announced Splatfest's first Challenges, and the
  /// Splatfests already running.
  static let cases = [
    ReminderCase(fixture: .normalDay, instant: "2026-10-20T12:00:00Z", reminders: [
      Reminder(.challenge, "2026-10-23T02:00:00Z"),
      Reminder(.challenge, "2026-10-30T02:00:00Z"),
    ]),
    ReminderCase(fixture: .bigRun, instant: "2026-09-07T12:00:00Z", reminders: [
      Reminder(.challenge, "2026-09-08T02:00:00Z"),
      Reminder(.bigRun, "2026-09-12T00:00:00Z"),
      Reminder(.challenge, "2026-09-17T02:00:00Z"),
    ]),
    ReminderCase(fixture: .eggstraWork, instant: "2026-08-28T12:00:00Z", reminders: [
      Reminder(.eggstraWork, "2026-08-29T00:00:00Z"),
      Reminder(.challenge, "2026-08-30T00:00:00Z"),
    ]),
    ReminderCase(fixture: .splatfestAnnounced, instant: "2026-10-30T12:00:00Z", reminders: [
      Reminder(.splatfest, "2026-10-31T00:00:00Z"),
      Reminder(.challenge, "2026-11-10T02:00:00Z"),
    ]),
    ReminderCase(fixture: .splatfestSecondHalf, instant: "2026-11-01T05:23:00Z", reminders: [
      Reminder(.challenge, "2026-11-10T02:00:00Z"),
      Reminder(.challenge, "2026-11-19T02:00:00Z"),
    ]),
    ReminderCase(fixture: .splatfestEnd, instant: "2026-08-23T20:00:00Z", reminders: [
      Reminder(.challenge, "2026-08-28T02:00:00Z"),
      Reminder(.eggstraWork, "2026-08-29T00:00:00Z"),
      Reminder(.challenge, "2026-08-30T00:00:00Z"),
    ]),
  ]

  /// The reminders of a recorded schedules feed at `instant`, for `kinds`, in `language` in UTC.
  private func reminders(
    _ fixture: Fixture,
    at instant: String,
    for kinds: Set<EventReminder.Kind> = Set(EventReminder.Kind.allCases),
    in language: GameLanguage = .enUS)
    async throws -> [EventReminder]
  {
    try await Snapshot.schedules(fixture).eventReminders(
      for: ReminderSettings(kinds: kinds, language: language, timeZone: .gmt, hourCycle: .zeroToTwentyThree),
      after: date(instant))
  }

  // MARK: Requests

  @Test(arguments: cases)
  func `Every switch on reminds of each event still to start, once, in time order`(
    _ reminderCase: ReminderCase) async throws
  {
    let reminders = try await reminders(reminderCase.fixture, at: reminderCase.instant)

    #expect(reminders.map { Reminder($0.kind, $0.fireDate.formatted(.iso8601)) } == reminderCase.reminders)
  }

  @Test(arguments: cases, EventReminder.Kind.allCases)
  func `Only the kinds whose switch is on are reminded of`(
    _ reminderCase: ReminderCase,
    kind: EventReminder.Kind)
    async throws
  {
    let reminders = try await reminders(reminderCase.fixture, at: reminderCase.instant, for: [kind])

    #expect(reminders.map { Reminder($0.kind, $0.fireDate.formatted(.iso8601)) } ==
      reminderCase.reminders.filter { $0.kind == kind })
  }

  @Test(arguments: cases)
  func `Every switch off reminds of nothing`(_ reminderCase: ReminderCase) async throws {
    let reminders = try await reminders(reminderCase.fixture, at: reminderCase.instant, for: [])

    #expect(reminders.isEmpty)
  }

  @Test
  func `The normal day reminds of each Challenge at its first window`() async throws {
    let reminders = try await reminders(.normalDay, at: "2026-10-20T12:00:00Z", for: [.challenge])

    #expect(reminders.map(\.fireDate) == [date("2026-10-23T02:00:00Z"), date("2026-10-30T02:00:00Z")])
  }

  @Test
  func `A reminder is only for a start after the instant`() async throws {
    let atStart = try await reminders(.bigRun, at: "2026-09-12T00:00:00Z", for: [.bigRun])
    let justBefore = try await reminders(.bigRun, at: "2026-09-11T23:59:59Z", for: [.bigRun])

    #expect(atStart.isEmpty)
    #expect(justBefore.map(\.fireDate) == [date("2026-09-12T00:00:00Z")])
  }

  @Test
  func `Nothing is reminded of before the schedules feed's first good response`() {
    let settings: ReminderSettings = .init(
      kinds: Set(EventReminder.Kind.allCases),
      language: .enUS,
      timeZone: .gmt,
      hourCycle: .zeroToTwentyThree)

    #expect(Snapshot().eventReminders(for: settings, after: date("2026-10-20T12:00:00Z")).isEmpty)
  }

  /// Every fixture calls for a handful, so the cap never binds on real data.
  @Test(arguments: cases)
  func `The reminders stay far below the system's 64 pending`(_ reminderCase: ReminderCase) async throws {
    let reminders = try await reminders(reminderCase.fixture, at: reminderCase.instant)

    #expect(reminders.count < 64)
    #expect(reminders.count <= EventReminder.maximumCount)
    #expect(EventReminder.maximumCount < 64)
  }

  // MARK: Identifiers

  @Test
  func `Identifiers carry the app's namespace, the kind and the start`() async throws {
    let reminders = try await reminders(.bigRun, at: "2026-09-07T12:00:00Z")

    #expect(reminders.map(\.id) == [
      "io.tianwei.ikalendar3.reminder.challenge.1788832800",
      "io.tianwei.ikalendar3.reminder.bigRun.1789171200",
      "io.tianwei.ikalendar3.reminder.challenge.1789610400",
    ])
  }

  /// A rebuild later, in another language, on a feed fetched again, names each event's reminder
  /// alike, so replacing the pending reminders replaces each in place.
  @Test
  func `Identifiers are stable across rebuilds`() async throws {
    let first = try await reminders(.bigRun, at: "2026-09-07T12:00:00Z")
    let later = try await Snapshot.schedules(.bigRun, fetchedAt: date("2026-09-08T12:00:00Z")).eventReminders(
      for: ReminderSettings(
        kinds: Set(EventReminder.Kind.allCases),
        language: .jaJP,
        timeZone: TimeZone(identifier: "Asia/Tokyo") ?? .gmt,
        hourCycle: .oneToTwelve),
      after: date("2026-09-08T12:00:00Z"))

    #expect(first.dropFirst().map(\.id) == later.map(\.id))
    #expect(Set(first.map(\.id)).count == first.count)
  }

  // MARK: Text

  @Test
  func `The Big Run reminder names the event and reads its sentence at its start`() async throws {
    let reminder = try #require(try await reminders(.bigRun, at: "2026-09-07T12:00:00Z", for: [.bigRun]).first)

    #expect(reminder.title == "Big Run starts now")
    #expect(reminder.body ==
      "Big Run: Wahoo World with Random, Random, Random, and Random, "
      + "from Saturday 00:00 to Monday 00:00, 48 hours left.")
  }

  @Test
  func `A Challenge reminder names the Challenge itself`() async throws {
    let reminder = try #require(try await reminders(.normalDay, at: "2026-10-20T12:00:00Z").first)

    #expect(reminder.title == "Dualies at Ten Paces starts now")
    #expect(reminder.body ==
      "Dualies at Ten Paces: Splat Zones on Um'ami Ruins and Sturgeon Shipyard, from 02:00 to 04:00, 2 hours left.")
  }

  @Test(arguments: GameLanguage.allCases)
  func `Reminder text resolves in every text set`(_ language: GameLanguage) async throws {
    for reminderCase in Self.cases {
      let reminders = try await reminders(reminderCase.fixture, at: reminderCase.instant, in: language)
      for reminder in reminders {
        #expect(!reminder.title.contains("reminders."), "\(reminder.title)")
        #expect(!reminder.title.contains("%"), "\(reminder.title)")
        #expect(!reminder.body.isEmpty)
      }
    }
    for text in ReminderText.allCases {
      #expect(text.text(in: language) != text.rawValue, "\(text)")
    }
  }
}
