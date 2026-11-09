//
//  FeedClientTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - FeedClientTests

/// The transport contract: what each answer does to the cache, and what each request carries.
final class FeedClientTests {
  private let directory: URL
  private let transport: ScriptedTransport = .init()
  private let clock: SettableClock = .init(date("2026-10-20T12:05:00Z"))

  init() throws {
    directory = try makeTestDirectory()
  }

  deinit {
    try? FileManager.default.removeItem(at: directory)
  }

  /// A client on the test's directory, as a new process would build it.
  private func makeClient(timeout: Duration = FeedClient.resourceTimeout) -> FeedClient {
    FeedClient(
      transport: transport,
      cache: FeedCache(directory: directory),
      appVersion: "1.0.0",
      timeout: timeout,
      now: { [clock] in clock.now })
  }

  // MARK: - Outcomes

  @Test
  func `An initial 200 fills the empty cache with its body, ETag and fetch time`() async throws {
    let body = try Fixture.normalDay.data()
    transport.reply(to: Feed.schedules.url, with: .ok(body, etag: #""b39cd2e7""#))

    let outcome = await makeClient().fetch(.schedules)

    #expect(outcome == .updated)
    #expect(FeedCache(directory: directory).record(for: .schedules) == FeedRecord(
      body: body,
      etag: #""b39cd2e7""#,
      fetchTime: date("2026-10-20T12:05:00Z")))
  }

  @Test
  func `A changed 200 replaces body, ETag and fetch time together`() async throws {
    let client = makeClient()
    try transport.reply(to: Feed.schedules.url, with: .ok(Fixture.normalDay.data(), etag: #""b39cd2e7""#))
    _ = await client.fetch(.schedules)
    let changed = try Fixture.bigRun.data()
    transport.reply(to: Feed.schedules.url, with: .ok(changed, etag: #""dce9980d""#))
    clock.now = date("2026-10-20T13:05:00Z")

    let outcome = await client.fetch(.schedules)

    #expect(outcome == .updated)
    #expect(client.cache.record(for: .schedules) == FeedRecord(
      body: changed,
      etag: #""dce9980d""#,
      fetchTime: date("2026-10-20T13:05:00Z")))
  }

  @Test
  func `A 304 keeps the stored body and ETag and renews the fetch time`() async throws {
    let client = makeClient()
    let body = try Fixture.normalDay.data()
    transport.reply(to: Feed.schedules.url, with: .ok(body, etag: #""b39cd2e7""#))
    _ = await client.fetch(.schedules)
    transport.reply(to: Feed.schedules.url, with: .notModified)
    clock.now = date("2026-10-20T13:05:00Z")

    let outcome = await client.fetch(.schedules)

    #expect(outcome == .confirmed)
    #expect(client.cache.record(for: .schedules) == FeedRecord(
      body: body,
      etag: #""b39cd2e7""#,
      fetchTime: date("2026-10-20T13:05:00Z")))
  }

  @Test(arguments: [
    (ScriptedTransport.Reply.ok(Data("<html>Bad gateway</html>".utf8), etag: #""e1""#), FetchFailure.undecodable),
    (.ok(Data(#"{"data":null}"#.utf8), etag: #""e2""#), .undecodable),
    (.status(500), .status(500)),
    (.status(404), .status(404)),
  ])
  func `An answer that is not a good 200 or a 304 fails and keeps the previous record`(
    _ reply: ScriptedTransport.Reply,
    failure: FetchFailure)
    async throws
  {
    let client = makeClient()
    try transport.reply(to: Feed.schedules.url, with: .ok(Fixture.normalDay.data(), etag: #""b39cd2e7""#))
    _ = await client.fetch(.schedules)
    let previous = client.cache.record(for: .schedules)
    transport.reply(to: Feed.schedules.url, with: reply)
    clock.now = date("2026-10-20T13:05:00Z")

    let outcome = await client.fetch(.schedules)

    #expect(outcome == .failed(failure))
    #expect(client.cache.record(for: .schedules) == previous)
  }

  @Test(arguments: [ScriptedTransport.Reply.failure(URLError(.notConnectedToInternet)), .hang])
  func `A transport error or a hang fails only that feed and keeps its record`(
    _ reply: ScriptedTransport.Reply)
    async throws
  {
    let client = makeClient(timeout: .milliseconds(200))
    try transport.reply(to: Feed.schedules.url, with: .ok(Fixture.normalDay.data(), etag: #""b39cd2e7""#))
    try transport.reply(to: Feed.festivals.url, with: .ok(Fixture.festivals.data(), etag: #""f1""#))
    _ = await client.fetch(.schedules)
    let previous = client.cache.record(for: .schedules)
    transport.reply(to: Feed.schedules.url, with: reply)
    clock.now = date("2026-10-20T13:05:00Z")

    async let schedules = client.fetch(.schedules)
    async let festivals = client.fetch(.festivals)

    #expect(await schedules == .failed(.noAnswer))
    #expect(await festivals == .updated)
    #expect(client.cache.record(for: .schedules) == previous)
  }

  @Test
  func `A good answer the cache cannot write fails the feed`() async throws {
    let blocked = directory.appending(path: "blocked")
    try Data().write(to: blocked)
    let client: FeedClient = .init(transport: transport, cache: FeedCache(directory: blocked), appVersion: "1.0.0")
    try transport.reply(to: Feed.schedules.url, with: .ok(Fixture.normalDay.data(), etag: #""b39cd2e7""#))

    #expect(await client.fetch(.schedules) == .failed(.notStored))
  }

  // MARK: - Requests

  @Test
  func `Every request goes to splatoon3 ink or its asset host`() async throws {
    let client = makeClient()
    try transport.reply(to: Feed.schedules.url, with: .ok(Fixture.splatfestSecondHalf.data(), etag: #""s""#))
    try transport.reply(to: Feed.festivals.url, with: .ok(Fixture.festivals.data(), etag: #""f""#))
    let feeds = [Feed.schedules, .festivals] + GameLanguage.allCases.map(Feed.locale)
    for feed in feeds {
      _ = await client.fetch(feed)
    }
    let snapshot = await client.cache.snapshot()
    let splatfest = try #require(snapshot.splatfest)
    try transport.reply(to: #require(splatfest.artURL), with: .ok(Data([0x89]), etag: nil))
    clock.now = date("2026-11-01T05:23:00Z")
    await client.updateSplatfestArt(for: splatfest)

    let hosts = transport.requests.map { $0.url?.host() }
    #expect(hosts.count == feeds.count + 1)
    #expect(Set(hosts) == ["splatoon3.ink", "assets.splatoon3.ink"])
  }

  @Test
  func `Every request names the app, its version and its contact in the User-Agent`() async throws {
    let client = makeClient()
    try transport.reply(to: Feed.schedules.url, with: .ok(Fixture.normalDay.data(), etag: #""b39cd2e7""#))
    _ = await client.fetch(.schedules)
    transport.reply(to: Feed.schedules.url, with: .notModified)
    _ = await client.fetch(.schedules)
    _ = await client.fetch(.festivals)

    #expect(transport.requests.count == 3)
    for request in transport.requests {
      #expect(
        request.value(forHTTPHeaderField: "User-Agent")
          == "ikalendar3/1.0.0 (+https://ikalendar.app/3; ikalendar3@tianwei.io)")
    }
  }

  /// A Brotli response's ETag comes back weak; it goes back as received.
  @Test(arguments: [#""dce9980d""#, #"W/"dce9980d""#])
  func `While a valid body is stored, If-None-Match is its ETag byte for byte`(etag: String) async throws {
    let client = makeClient()
    try transport.reply(to: Feed.schedules.url, with: .ok(Fixture.normalDay.data(), etag: etag))
    _ = await client.fetch(.schedules)
    _ = await client.fetch(.schedules)

    let requests = transport.requests
    #expect(requests.first?.value(forHTTPHeaderField: "If-None-Match") == nil)
    #expect(requests.last?.value(forHTTPHeaderField: "If-None-Match") == etag)
  }

  /// Otherwise a 304 would confirm a body the cache cannot use, again and again.
  @Test(arguments: [Data(), Data("{}".utf8)])
  func `With an ETag stored but no valid body, the request carries no If-None-Match`(body: Data) async throws {
    let client = makeClient()
    try client.cache.commit(
      FeedRecord(body: body, etag: #""b39cd2e7""#, fetchTime: date("2026-10-20T11:05:00Z")),
      for: .schedules)
    transport.reply(to: Feed.schedules.url, with: .notModified)

    let outcome = await client.fetch(.schedules)

    #expect(transport.requests.only?.value(forHTTPHeaderField: "If-None-Match") == nil)
    #expect(outcome == .failed(.status(304)))
  }
}
