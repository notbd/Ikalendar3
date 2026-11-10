//
//  ReminderSwitchesTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)
import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaIntents

// MARK: - ReminderSwitchesTests

/// Pins that the pending reminders follow the switches wherever they are written: the shell
/// observes the preferences store, so no writer has to ask for a rebuild.
///
/// The Big Run day is rebased to now, the shell's clock, so its Big Run starts four and a half
/// days from now and has a reminder while its switch is on.
@MainActor
struct ReminderSwitchesTests {
  @Test
  func `A reminder switch written on the store itself rebuilds the pending reminders`() async throws {
    let suite = "ReminderSwitchesTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let directory: URL = FileManager.default.temporaryDirectory.appending(path: suite, directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: directory) }
    let now: Date = .init()
    let run = try FixtureLaunch(schedules: .bigRun, folder: Fixture.folder, instant: Self.instant, isRebased: true)
      .prepare(sharedCache: FeedCache(directory: directory), now: now)
    let engine: RefreshEngine = .init(client: run.client, language: .enUS)
    await engine.refresh()
    let preferences: PreferenceStore = .init(defaults: defaults)
    let center: FakePendingRequests = .init()
    let shell: EffectsShell = .init(
      engine: engine,
      preferences: preferences,
      reminders: ReminderReplacements(center: center))

    let following = shell.followReminderSwitches()
    defer { following.cancel() }
    // As Debug Options does, and as no screen asks for a rebuild.
    preferences.isBigRunReminderOn = true
    await waitUntil { !center.pending.isEmpty }
    let switchedOn = center.pending
    preferences.resetAppPreferences()
    await waitUntil { center.pending.isEmpty }

    #expect(switchedOn == [EventReminder.namespace + "bigRun.\(Self.bigRunStart(rebasedTo: now))"])
    #expect(center.pending.isEmpty)
  }

  /// At launch the engine has published nothing yet, so a rebuild from the first reading would
  /// remove every pending reminder until a refresh commits a feed.
  @Test
  func `The observer's first reading of the switches leaves the pending reminders`() async throws {
    let suite = "ReminderSwitchesTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let directory: URL = FileManager.default.temporaryDirectory.appending(path: suite, directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: directory) }
    let preferences: PreferenceStore = .init(defaults: defaults)
    preferences.isBigRunReminderOn = true
    let pending = EventReminder.namespace + "bigRun.1789171200"
    let center: FakePendingRequests = .init(pending: [pending])
    let client: FeedClient = .init(transport: ScriptedTransport(), cache: FeedCache(directory: directory))
    let shell: EffectsShell = .init(
      engine: RefreshEngine(client: client, language: .enUS),
      preferences: preferences,
      reminders: ReminderReplacements(center: center))

    let following = shell.followReminderSwitches()
    defer { following.cancel() }
    // Nothing marks a skipped reading, so the observer gets the main actor for a while; a rebuild
    // would run on it at once.
    try await Task.sleep(for: .milliseconds(200))
    let afterFirstReading = center.pending
    // The observer was following all along: a change rebuilds, here from the empty snapshot.
    preferences.isEggstraWorkReminderOn = true
    await waitUntil { center.pending.isEmpty }

    #expect(afterFirstReading == [pending])
  }

  /// An intent's shell builds its store as the intent starts, a copy of the suite then; the
  /// player turns Big Run off in Settings while the intent's refresh is held in flight.
  @Test
  func `A switch turned off during an intent's refresh stays off in that intent's replacement`() async throws {
    let suite = "ReminderSwitchesTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let directory: URL = FileManager.default.temporaryDirectory.appending(path: suite, directoryHint: .isDirectory)
    defer { try? FileManager.default.removeItem(at: directory) }
    let settings: PreferenceStore = .init(defaults: defaults)
    settings.isBigRunReminderOn = true
    let transport: ScriptedTransport = try .bigRunDay(rebasedTo: Date(), from: Self.instant)
    let center: FakePendingRequests = .init()
    let client: FeedClient = .init(transport: transport, cache: FeedCache(directory: directory))
    let intentShell: EffectsShell = .init(
      engine: RefreshEngine(client: client, language: .enUS),
      preferences: PreferenceStore(defaults: defaults),
      reminders: ReminderReplacements(center: center))

    transport.hold()
    let run = Task { await intentShell.run() }
    await waitUntil { !transport.requests.isEmpty }
    settings.isBigRunReminderOn = false
    transport.release()
    let result = await run.value

    // Only a committed schedules feed plans reminders, so the empty list below is the switch's
    // doing and not a refresh that planned nothing.
    #expect(result.outcomes[.schedules] == .fetched(.updated))
    #expect(center.pending.isEmpty)
  }

  /// The instant the Big Run day moves to now.
  static private let instant: Date = date("2026-09-07T12:00:00Z")

  /// The Big Run's start, in seconds since 1970 as its reminder's identifier writes them, once
  /// the day is rebased to `now` (`FixtureLaunch.prepare`).
  static private func bigRunStart(rebasedTo now: Date) -> Int {
    let offset = now.timeIntervalSince(instant).rounded(.towardZero)
    return Int(date("2026-09-12T00:00:00Z").timeIntervalSince1970 + offset)
  }
}

// MARK: - ScriptedTransport

extension ScriptedTransport {
  /// Answers an English engine's three feeds with the Big Run day, moved from `instant` to `now`
  /// as a rebased fixture launch moves it.
  static func bigRunDay(rebasedTo now: Date, from instant: Date) throws -> ScriptedTransport {
    let offset: Duration = .seconds(now.timeIntervalSince(instant).rounded(.towardZero))
    let transport: ScriptedTransport = .init()
    try transport.reply(to: Feed.schedules.url, with: .ok(Fixture.rebase(Fixture.bigRun.data(), by: offset), etag: nil))
    try transport.reply(to: Feed.festivals.url, with: .ok(Fixture.festivals.data(), etag: nil))
    try transport.reply(to: Feed.locale(.enUS).url, with: .ok(Fixture.localeEnUS.data(), etag: nil))
    return transport
  }
}

// MARK: - waitUntil

/// Waits until `condition` holds, checking every 10 ms, and records an issue if it does not
/// within `timeout`.
@MainActor
func waitUntil(
  timeout: Duration = .seconds(10),
  sourceLocation: SourceLocation = #_sourceLocation,
  _ condition: () -> Bool)
  async
{
  let deadline: ContinuousClock.Instant = .now + timeout
  while !condition() {
    if ContinuousClock.now >= deadline {
      Issue.record("Condition not met within \(timeout)", sourceLocation: sourceLocation)
      return
    }
    try? await Task.sleep(for: .milliseconds(10))
  }
}
#endif
