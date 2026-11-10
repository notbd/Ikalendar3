//
//  AnswerSourceTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaIntents

// MARK: - AnswerSourceTests

/// Pins that a Siri answer is the one at the moment its refresh ends. The test holds the refresh's
/// requests in flight across the normal day's 14:00 UTC Rotation boundary, with a scripted clock.
@MainActor
struct AnswerSourceTests {
  @Test
  func `A refresh across a Rotation boundary answers with the Rotation it ends in`() async throws {
    let asked: Date = date("2026-10-20T13:59:59Z")
    let answered: Date = date("2026-10-20T14:00:03Z")
    let clock: SettableClock = .init(asked)
    let transport: ScriptedTransport = .init()
    let payloads: [(Feed, Fixture)] = [
      (.schedules, .normalDay),
      (.festivals, .festivals),
      (.locale(.enUS), .localeEnUS),
    ]
    for (feed, fixture) in payloads {
      try transport.reply(to: feed.url, with: .ok(fixture.data(), etag: nil))
    }
    let suite = "AnswerSourceTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let directory: URL = FileManager.default.temporaryDirectory.appending(path: suite, directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: directory) }
    let engine: RefreshEngine = .init(
      client: FeedClient(transport: transport, cache: FeedCache(directory: directory), now: { clock.now }),
      language: .enUS)
    let timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
    let source: AnswerSource = .init(
      shell: EffectsShell(
        engine: engine,
        preferences: PreferenceStore(defaults: defaults),
        reminders: ReminderReplacements(center: FakePendingRequests())),
      language: .enUS,
      timeZone: timeZone,
      hourCycle: .oneToTwelve,
      clock: clock)

    transport.hold()
    let answer = Task { await source.answer(NowIntent(mode: .xBattle)) }
    await waitUntil { transport.requests.count == 3 }
    clock.now = answered
    transport.release()
    let text = await answer.value

    let answers: SiriAnswers = .init(
      snapshot: engine.snapshot,
      language: .enUS,
      timeZone: timeZone,
      hourCycle: .oneToTwelve)
    #expect(text == answers.now(in: .battle(.x), at: answered))
    #expect(text != answers.now(in: .battle(.x), at: asked))
  }
}
#endif
