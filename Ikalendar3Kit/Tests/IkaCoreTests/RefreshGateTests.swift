//
//  RefreshGateTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - RefreshGateTests

/// The one network gate: at most one answered request per feed an hour, a back-off while
/// requests go unanswered, and one request at a time across engines on one directory.
@MainActor
final class RefreshGateTests {
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

  // MARK: - Answered requests

  /// Every entry point calls `refresh()`; a second engine stands in for another process.
  @Test
  func `Within an hour of an answer, no engine sends a request and the cache is re-projected`() async throws {
    try transport.scriptFeeds()
    let engine = makeEngine()
    await engine.refresh()
    let committed = await FeedCache(directory: directory).snapshot()
    clock.now = date("2026-10-20T13:04:59Z")

    let again = await engine.refresh()
    let elsewhere = await makeEngine().refresh()

    #expect(transport.requests.count == 3)
    for result in [again, elsewhere] {
      #expect(result.outcomes == [.schedules: .gateClosed, .festivals: .gateClosed, .locale(.enUS): .gateClosed])
      #expect(result.snapshot == committed)
    }
  }

  @Test
  func `An hour after an answer, each feed sends one request, conditional on its stored ETag`() async throws {
    try transport.scriptFeeds()
    let engine = makeEngine()
    await engine.refresh()
    transport.replyToFeeds(with: .notModified)
    clock.now = date("2026-10-20T13:05:00Z")

    let result = await engine.refresh()

    let requests = transport.requests.dropFirst(3)
    #expect(requests.count == 3)
    #expect(Set(requests.map { $0.value(forHTTPHeaderField: "If-None-Match") }) == [
      #""normalDay""#,
      #""festivals""#,
      #""en-US""#,
    ])
    #expect(result.outcomes == [
      .schedules: .fetched(.confirmed),
      .festivals: .fetched(.confirmed),
      .locale(.enUS): .fetched(.confirmed),
    ])
  }

  @Test(arguments: [
    (ScriptedTransport.Reply.status(500), FetchFailure.status(500)),
    (.ok(Data("<html>Bad gateway</html>".utf8), etag: #""e1""#), .undecodable),
  ])
  func `An answered failure closes the gate for the hour`(
    _ reply: ScriptedTransport.Reply,
    failure: FetchFailure)
    async
  {
    transport.replyToFeeds(with: reply)
    let engine = makeEngine()
    let failed = await engine.refresh()
    clock.now = date("2026-10-20T13:04:59Z")

    let inside = await engine.refresh()
    clock.now = date("2026-10-20T13:05:00Z")
    await engine.refresh()

    #expect(failed.outcomes[.schedules] == .fetched(.failed(failure)))
    #expect(inside.outcomes[.schedules] == .gateClosed)
    #expect(transport.requests.count == 6)
  }

  /// Otherwise a device clock set back a day would keep the gate closed for that day.
  @Test
  func `A clock set back before the last attempt does not keep the gate closed`() async throws {
    try transport.scriptFeeds()
    let engine = makeEngine()
    await engine.refresh()
    clock.now = date("2026-10-19T12:05:00Z")

    let result = await engine.refresh()

    #expect(result.outcomes[.schedules] == .fetched(.updated))
    #expect(transport.requests.count == 6)
  }

  // MARK: - Unanswered requests

  @Test
  func `Unanswered requests back off from 30 s, doubling up to an hour, and an answer resets it`() async {
    let engine = makeEngine()
    await engine.refresh()
    var sent = 3
    // The wait each unanswered request sets before the next request.
    let steps: [TimeInterval] = [30, 60, 120, 240, 480, 960, 1920, 3600, 3600]
    for step in steps {
      let last = clock.now
      clock.now = last.addingTimeInterval(step - 1)
      await engine.refresh()
      #expect(transport.requests.count == sent, "\(step) s")
      clock.now = last.addingTimeInterval(step)
      await engine.refresh()
      sent += 3
      #expect(transport.requests.count == sent, "\(step) s")
    }

    // An answer: the gate closes for the hour, and the next unanswered request waits 30 s again.
    transport.replyToFeeds(with: .status(503))
    clock.now = clock.now.addingTimeInterval(3600)
    await engine.refresh()
    transport.replyToFeeds(with: .failure(URLError(.timedOut)))
    clock.now = clock.now.addingTimeInterval(3600)
    await engine.refresh()
    clock.now = clock.now.addingTimeInterval(30)
    let afterReset = await engine.refresh()

    #expect(transport.requests.count == sent + 9)
    #expect(afterReset.outcomes[.schedules] == .fetched(.failed(.noAnswer)))
  }

  // MARK: - One request at a time

  @Test
  func `Overlapping refreshes in one engine join one refresh`() async throws {
    try transport.scriptFeeds()
    transport.hold()
    let engine = makeEngine()
    let first = Task { await engine.refresh() }
    await waitUntil { transport.requests.count == 3 }
    let second = Task { await engine.refresh() }
    try await Task.sleep(for: .milliseconds(100))

    transport.release()
    let (joined, joining) = await (first.value, second.value)

    #expect(transport.requests.count == 3)
    #expect(joining == joined)
    #expect(joining.outcomes[.schedules] == .fetched(.updated))
  }

  /// The two engines stand in for the app and an intent in the app process. The first engine's
  /// answers are held until the second has found its leases, which fixes the order.
  @Test
  func `Two engines on one directory send one request per feed, and the waiting one publishes the commit`()
    async throws
  {
    try transport.scriptFeeds()
    transport.hold()
    let sender = makeEngine()
    let waiter = makeEngine()
    let sending = Task { await sender.refresh() }
    await waitUntil { transport.requests.count == 3 }
    let waiting = Task { await waiter.refresh() }
    try await Task.sleep(for: .milliseconds(300))

    transport.release()
    let (sent, waited) = await (sending.value, waiting.value)

    #expect(transport.requests.count == 3)
    #expect(sent.outcomes[.schedules] == .fetched(.updated))
    #expect(waited.outcomes == [.schedules: .gateClosed, .festivals: .gateClosed, .locale(.enUS): .gateClosed])
    #expect(waiter.snapshot.schedules != nil)
    #expect(waiter.snapshot == sender.snapshot)
  }

  /// No order is fixed here: every engine claims at once, so only the file lock keeps the claims
  /// apart.
  @Test
  func `Engines refreshing at once on one directory send one request per feed`() async throws {
    try transport.scriptFeeds()
    transport.hold()
    let engines = (1 ... 8).map { _ in makeEngine() }

    let refreshes = engines.map { engine in Task { await engine.refresh() } }
    await waitUntil { transport.requests.count >= 3 }
    try await Task.sleep(for: .milliseconds(300))
    transport.release()
    for refresh in refreshes {
      _ = await refresh.value
    }

    #expect(transport.requests.count == 3)
    #expect(engines.allSatisfy { $0.snapshot == engines[0].snapshot && $0.snapshot.schedules != nil })
  }

  /// A claim written straight through the gate stands in for an engine the system killed
  /// mid-request: it never writes an outcome.
  @Test
  func `A claim left by a stopped engine holds each feed until its lease passes, then frees it`() async throws {
    try transport.scriptFeeds()
    let stopped: FeedGate = .init(
      directory: directory,
      lease: FeedClient.resourceTimeout,
      now: { [clock] in clock.now })
    for feed in [Feed.schedules, .festivals, .locale(.enUS)] {
      _ = stopped.claim(.feed(feed))
    }
    clock.now = date("2026-10-20T12:05:29Z")
    let engine = makeEngine()

    let refresh = Task { await engine.refresh() }
    try await Task.sleep(for: .milliseconds(300))
    #expect(transport.requests.isEmpty)
    clock.now = date("2026-10-20T12:05:30Z")
    let result = await refresh.value

    #expect(transport.requests.count == 3)
    #expect(result.outcomes[.schedules] == .fetched(.updated))
  }
}
