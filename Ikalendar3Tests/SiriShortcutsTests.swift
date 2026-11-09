//
//  SiriShortcutsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import Foundation
import IkaCore
import IkaFixtures
import IkaIntents
import OSLog
import Testing

// MARK: - SiriShortcutsTests

/// The question intents as the app's process runs them: a run of the effects shell over a
/// recorded feed, then ticket 21's answer, with a log line naming the process.
@MainActor
struct SiriShortcutsTests {
  @Test
  func `The now intent refreshes through the shell and answers as Siri answers`() async throws {
    let instant: Date = date("2026-10-20T13:00:00Z")
    let run = try FixtureLaunch(schedules: .normalDay, folder: Fixture.folder, instant: instant, isRebased: false)
      .prepare(sharedCache: FeedCache(directory: FileManager.default.temporaryDirectory), now: Date())
    let source: AnswerSource = try .init(
      shell: EffectsShell(engine: RefreshEngine(client: run.client, language: .enUS)),
      language: .enUS,
      timeZone: #require(TimeZone(identifier: "America/Los_Angeles")),
      hourCycle: .oneToTwelve)
    let start: Date = .now

    let answer = await source.answer(NowIntent(mode: .xBattle), at: instant)

    #expect(answer ==
      "X Battle: Tower Control on Mahi-Mahi Resort and Robo ROM-en, "
      + "from 5:00\u{202F}AM to 7:00\u{202F}AM, 1 hour left.")
    #expect(try Self.intentLogLines(since: start) == ["NowIntent ran in Ikalendar3"])
  }

  /// The `intents` category's lines this process logged since `start`.
  static private func intentLogLines(since start: Date) throws -> [String] {
    let store: OSLogStore = try .init(scope: .currentProcessIdentifier)
    let predicate: NSPredicate = .init(
      format: "subsystem == %@ AND category == %@",
      Bundle.main.bundleIdentifier ?? "",
      "intents")
    return try store.getEntries(at: store.position(date: start), matching: predicate)
      .compactMap { ($0 as? OSLogEntryLog)?.composedMessage }
  }
}
#endif
