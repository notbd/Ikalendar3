//
//  RefreshEngineTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - RefreshEngineTests

/// What a refresh publishes: the cached snapshot first, each feed's outcome, stale marks and the
/// in-flight status.
@MainActor
final class RefreshEngineTests {
  private let directory: URL
  private let transport: ScriptedTransport = .init()
  private let clock: SettableClock = .init(date("2026-10-20T12:05:00Z"))

  init() throws {
    directory = try makeTestDirectory()
  }

  deinit {
    try? FileManager.default.removeItem(at: directory)
  }

  /// An engine on the test's directory, as a new process would build it.
  private func makeEngine() -> RefreshEngine {
    RefreshEngine(directory: directory, transport: transport, clock: clock)
  }

  // MARK: - Snapshot

  @Test
  func `A first refresh requests each feed once and publishes what it committed`() async throws {
    try transport.scriptFeeds()
    let engine = makeEngine()

    let result = await engine.refresh()

    #expect(transport.requests.compactMap(\.url?.absoluteString).sorted() == [
      "https://splatoon3.ink/data/festivals.json",
      "https://splatoon3.ink/data/locale/en-US.json",
      "https://splatoon3.ink/data/schedules.json",
    ])
    #expect(result.outcomes == [
      .schedules: .fetched(.updated),
      .festivals: .fetched(.updated),
      .locale(.enUS): .fetched(.updated),
    ])
    let committed = await FeedCache(directory: directory).snapshot()
    #expect(committed.schedules?.fetchTime == clock.now)
    #expect(result.snapshot == committed)
    #expect(engine.snapshot == committed)
    #expect(engine.status == .loaded)
  }

  /// The second engine stands in for the app relaunched an hour later.
  @Test
  func `The cached snapshot is published before any request and stays shown while requests are in flight`()
    async throws
  {
    try transport.scriptFeeds()
    await makeEngine().refresh()
    let cached = await FeedCache(directory: directory).snapshot()
    transport.replyToFeeds(with: .notModified)
    transport.hold()
    clock.now = date("2026-10-20T13:05:00Z")
    let engine = makeEngine()

    let refresh = Task { await engine.refresh() }
    await waitUntil { transport.requests.count == 6 }
    let shown = engine.snapshot
    let status = engine.status
    transport.release()
    _ = await refresh.value

    #expect(shown == cached)
    #expect(status == .loading)
    #expect(engine.snapshot.schedules?.fetchTime == date("2026-10-20T13:05:00Z"))
    #expect(engine.status == .loaded)
  }

  // MARK: - Status

  @Test
  func `The status moves through loading to its end, and an equal status is not published again`() async throws {
    try transport.scriptFeeds()
    let engine = makeEngine()
    let statuses: ChangeLog = .init { engine.status }
    let settled: ChangeLog = .init { engine.settledStatus }

    await engine.refresh()
    await waitUntil { statuses.values.count == 1 }
    clock.now = date("2026-10-20T13:05:00Z")
    transport.replyToFeeds(with: .status(500))
    await engine.refresh()
    await waitUntil { statuses.values.count == 3 }
    clock.now = date("2026-10-20T14:05:00Z")
    await engine.refresh()
    await waitUntil { statuses.values.count == 5 }

    #expect(statuses.values == [.loaded, .loading, .failed, .loading, .failed])
    #expect(settled.values == [.loaded, .failed])
  }

  // MARK: - Failures

  @Test
  func `One feed failing keeps the other feeds fresh and its own last good data, marked stale`() async throws {
    try transport.scriptFeeds()
    let engine = makeEngine()
    await engine.refresh()
    let cached = await FeedCache(directory: directory).snapshot()
    transport.replyToFeeds(with: .notModified)
    transport.reply(to: Feed.schedules.url, with: .status(500))
    clock.now = date("2026-10-20T13:05:00Z")

    let result = await engine.refresh()

    #expect(result.outcomes == [
      .schedules: .fetched(.failed(.status(500))),
      .festivals: .fetched(.confirmed),
      .locale(.enUS): .fetched(.confirmed),
    ])
    let schedules = try #require(engine.snapshot.schedules)
    #expect(schedules.content == cached.schedules?.content)
    #expect(schedules.fetchTime == date("2026-10-20T12:05:00Z"))
    #expect(schedules.isStale)
    #expect(engine.snapshot.festivals?.fetchTime == date("2026-10-20T13:05:00Z"))
    #expect(engine.snapshot.festivals?.isStale == false)
    #expect(engine.snapshot.locales[.enUS]?.isStale == false)
    #expect(result.snapshot == engine.snapshot)
  }

  @Test
  func `With a cache and no network, a relaunched engine publishes the cached data, marked stale`() async throws {
    try transport.scriptFeeds()
    await makeEngine().refresh()
    let cached = await FeedCache(directory: directory).snapshot()
    transport.replyToFeeds(with: .failure(URLError(.notConnectedToInternet)))
    clock.now = date("2026-10-20T13:05:00Z")
    let engine = makeEngine()

    await engine.refresh()

    var expected = cached
    expected.schedules?.isStale = true
    expected.festivals?.isStale = true
    expected.locales[.enUS]?.isStale = true
    #expect(engine.snapshot == expected)
    #expect(engine.status == .failed)
  }

  @Test
  func `With an empty cache and no network, the empty state is published, and the next back-off step fetches`()
    async throws
  {
    let engine = makeEngine()

    let offline = await engine.refresh()
    try transport.scriptFeeds()
    clock.now = date("2026-10-20T12:05:29Z")
    let early = await engine.refresh()
    clock.now = date("2026-10-20T12:05:30Z")
    let online = await engine.refresh()

    #expect(offline.outcomes[.schedules] == .fetched(.failed(.noAnswer)))
    #expect(offline.snapshot == Snapshot())
    #expect(early.outcomes[.schedules] == .gateClosed)
    #expect(early.snapshot == Snapshot())
    #expect(online.outcomes[.schedules] == .fetched(.updated))
    #expect(engine.snapshot.schedules?.isStale == false)
    #expect(engine.status == .loaded)
  }

  /// Engine `relaunched` stands in for the app opened again after the failure; it renews the
  /// feed, as any process can.
  @Test
  func `A stale mark holds across later runs until any engine renews the feed, and a relaunch starts without it`()
    async throws
  {
    try transport.scriptFeeds()
    let engine = makeEngine()
    await engine.refresh()
    transport.reply(to: Feed.schedules.url, with: .failure(URLError(.timedOut)))
    clock.now = date("2026-10-20T13:05:00Z")
    await engine.refresh()

    clock.now = date("2026-10-20T13:05:10Z")
    let kept = await engine.refresh()
    let relaunched = makeEngine()
    let fresh = await relaunched.refresh()
    transport.reply(to: Feed.schedules.url, with: .notModified)
    clock.now = date("2026-10-20T13:05:30Z")
    let renewal = await relaunched.refresh()
    clock.now = date("2026-10-20T13:05:40Z")
    let cleared = await engine.refresh()

    #expect(kept.outcomes[.schedules] == .gateClosed)
    #expect(kept.snapshot.schedules?.isStale == true)
    #expect(fresh.snapshot.schedules?.isStale == false)
    #expect(renewal.outcomes[.schedules] == .fetched(.confirmed))
    #expect(cleared.outcomes[.schedules] == .gateClosed)
    #expect(cleared.snapshot.schedules?.isStale == false)
    #expect(cleared.snapshot.schedules?.fetchTime == date("2026-10-20T13:05:30Z"))
  }

  @Test
  func `An engine publishes another engine's commit at its next run, even while the gate is closed`()
    async throws
  {
    try transport.scriptFeeds()
    let engine = makeEngine()
    await engine.refresh()
    try transport.scriptFeeds(schedules: .bigRun)
    clock.now = date("2026-10-20T13:05:00Z")
    await makeEngine().refresh()
    clock.now = date("2026-10-20T13:10:00Z")

    let result = await engine.refresh()

    #expect(result.outcomes[.schedules] == .gateClosed)
    #expect(try await engine.snapshot.schedules?.content == ScheduleFeed.decode(from: Fixture.bigRun.data()))
    #expect(engine.snapshot.schedules?.fetchTime == date("2026-10-20T13:05:00Z"))
  }

  // MARK: - Splatfest art

  @Test
  func `A refresh downloads the Splatfest art once, and a refresh once it is over removes it`() async throws {
    let fixtures = try await Snapshot(
      schedules: .init(content: ScheduleFeed.decode(from: Fixture.splatfestSecondHalf.data()), fetchTime: clock.now),
      festivals: .init(content: FestivalFeed.decode(from: Fixture.festivals.data()), fetchTime: clock.now))
    let splatfest = try #require(fixtures.splatfest)
    let art: Data = .init([0x89, 0x50, 0x4E, 0x47])
    try transport.scriptFeeds(schedules: .splatfestSecondHalf)
    try transport.reply(to: #require(splatfest.artURL), with: .ok(art, etag: nil))
    clock.now = date("2026-11-01T05:23:00Z")
    let engine = makeEngine()
    let cache: FeedCache = .init(directory: directory)
    var artRequests: Int { transport.requests.count { $0.url == splatfest.artURL } }

    let first = await engine.refresh()
    let storedFile = cache.splatfestArt(for: splatfest.id)
    let stored = try storedFile.map { try Data(contentsOf: $0) }
    let cachedArt = await cache.snapshot().splatfestArt
    clock.now = date("2026-11-01T06:23:00Z")
    await engine.refresh()
    let requestsWhileOn = artRequests
    clock.now = splatfest.endTime
    let over = await engine.refresh()

    #expect(stored == art)
    // The first refresh publishes the art it downloaded, as the cache gives it to widgets.
    #expect(first.snapshot.splatfestArt == storedFile)
    #expect(cachedArt == storedFile)
    #expect(requestsWhileOn == 1)
    #expect(cache.splatfestArt(for: splatfest.id) == nil)
    #expect(over.snapshot.splatfestArt == nil)
    #expect(engine.snapshot.splatfestArt == nil)
    #expect(artRequests == 1)
  }
}
