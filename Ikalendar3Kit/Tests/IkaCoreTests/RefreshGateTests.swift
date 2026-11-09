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

  /// A client on the test's directory, whose gate the engines share.
  private func makeClient() -> FeedClient {
    FeedClient(transport: transport, cache: FeedCache(directory: directory), now: { [clock] in clock.now })
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

  /// A time sync steps the clock back by seconds, which must not let a second request out.
  @Test
  func `A clock stepped back less than a minute keeps the gate closed`() async throws {
    try transport.scriptFeeds()
    let engine = makeEngine()
    await engine.refresh()
    clock.now = date("2026-10-20T12:04:01Z")

    let result = await engine.refresh()

    #expect(result.outcomes[.schedules] == .gateClosed)
    #expect(transport.requests.count == 3)
  }

  /// The gate replaces the attempt file only by an atomic rename, so one that does not decode is
  /// damage, not a first use. Every key's records are in it, so no gate may reopen.
  @Test
  func `An attempt file that does not decode keeps every gate closed and stays as it is`() throws {
    let gate = makeClient().gate
    try gate.settle(#require(gate.claim(.feed(.schedules)).granted), isAnswered: true)
    let records = directory.appending(path: "attempts.plist")
    try Data("corrupt".utf8).write(to: records)

    let answered = gate.claim(.feed(.schedules))
    let neverClaimed = gate.claim(.feed(.festivals))

    #expect(answered.isClosed)
    #expect(neverClaimed.isClosed)
    #expect(try Data(contentsOf: records) == Data("corrupt".utf8))
  }

  /// A file nobody may read fails the read with an error other than a missing file, while the
  /// folder still lets the gate replace it.
  @Test
  func `An attempt file that cannot be read keeps the gate closed and stays as it is`() throws {
    let gate = makeClient().gate
    try gate.settle(#require(gate.claim(.feed(.schedules)).granted), isAnswered: true)
    let records = directory.appending(path: "attempts.plist")
    let answered = try Data(contentsOf: records)
    try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: records.path(percentEncoded: false))

    let claim = gate.claim(.feed(.schedules))
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: records.path(percentEncoded: false))

    #expect(claim.isClosed)
    #expect(try Data(contentsOf: records) == answered)
  }

  /// Sol's case: the clock set back 61 s, past a time sync's step, while the first request is in
  /// flight.
  @Test
  func `A clock set back during a request keeps the feed leased until the request settles`() throws {
    let gate = makeClient().gate
    let inFlight = try #require(gate.claim(.feed(.schedules)).granted)
    clock.now = date("2026-10-20T12:03:59Z")

    let during = gate.claim(.feed(.schedules))
    gate.settle(inFlight, isAnswered: true)
    let after = gate.claim(.feed(.schedules))

    #expect(during.isLeased)
    #expect(after.isClosed)
  }

  /// With no claim in between, the answer's hour still counts from the set-back clock.
  @Test
  func `An answer that comes after the clock was set back closes the gate for the hour`() throws {
    let gate = makeClient().gate
    let inFlight = try #require(gate.claim(.feed(.schedules)).granted)
    clock.now = date("2026-10-20T12:03:59Z")

    gate.settle(inFlight, isAnswered: true)
    let atOnce = gate.claim(.feed(.schedules))
    clock.now = date("2026-10-20T13:03:58Z")
    let lastSecond = gate.claim(.feed(.schedules))

    #expect(atOnce.isClosed)
    #expect(lastSecond.isClosed)
  }

  /// A set-back restarts the lease from the new time instead of ending it, so a claim the
  /// system killed still frees the feed a lease later, not after the time the clock lost.
  @Test
  func `A claim abandoned before the clock was set back frees the feed a lease after the set-back`() {
    let gate = makeClient().gate
    _ = gate.claim(.feed(.schedules))
    clock.now = date("2026-10-19T12:05:00Z")

    let setBack = gate.claim(.feed(.schedules))
    clock.now = date("2026-10-19T12:05:34Z")
    let held = gate.claim(.feed(.schedules))
    clock.now = date("2026-10-19T12:05:35Z")
    let freed = gate.claim(.feed(.schedules))

    #expect(setBack.isLeased)
    #expect(held.isLeased)
    #expect(freed.granted != nil)
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
    let isLeased = if case .leased = makeClient().gate.claim(.feed(.schedules)) { true } else { false }

    transport.release()
    let (sent, waited) = await (sending.value, waiting.value)

    #expect(isLeased)
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
  /// mid-request: it never writes an outcome. The lease outlasts the request's timeout by the time
  /// its answer takes to commit.
  @Test
  func `A claim left by a stopped engine holds each feed until its lease passes, then frees it`() async throws {
    try transport.scriptFeeds()
    let stopped = makeClient().gate
    for feed in [Feed.schedules, .festivals, .locale(.enUS)] {
      _ = stopped.claim(.feed(feed))
    }
    clock.now = date("2026-10-20T12:05:34Z")
    let engine = makeEngine()

    let refresh = Task { await engine.refresh() }
    try await Task.sleep(for: .milliseconds(300))
    #expect(transport.requests.isEmpty)
    clock.now = date("2026-10-20T12:05:35Z")
    let result = await refresh.value

    #expect(transport.requests.count == 3)
    #expect(result.outcomes[.schedules] == .fetched(.updated))
  }
}

// MARK: - FeedGate.Claim

extension FeedGate.Claim {
  /// The claimed attempt, or `nil` when the gate did not grant one.
  fileprivate var granted: Granted? {
    if case .claimed(let granted) = self { granted } else { nil }
  }

  fileprivate var isLeased: Bool {
    if case .leased = self { true } else { false }
  }

  fileprivate var isClosed: Bool {
    if case .closed = self { true } else { false }
  }
}
