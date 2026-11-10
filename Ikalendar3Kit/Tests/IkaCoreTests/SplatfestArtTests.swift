//
//  SplatfestArtTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - SplatfestArtTests

/// The current Splatfest's art: downloaded once into the cache's directory, gone once it is over.
final class SplatfestArtTests {
  private let directory: URL
  private let transport: ScriptedTransport = .init()
  /// Inside the 2026-11-01 Splatfest, which ends 2026-11-02 00:00 UTC.
  private let clock: SettableClock = .init(date("2026-11-01T05:23:00Z"))
  private let art: Data = .init([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

  init() throws {
    directory = try makeTestDirectory()
  }

  deinit {
    try? FileManager.default.removeItem(at: directory)
  }

  /// A client on the test's directory, as a new process would build it.
  private func makeClient() -> FeedClient {
    FeedClient(
      transport: transport,
      cache: FeedCache(directory: directory),
      appVersion: "1.0.0",
      now: { [clock] in clock.now })
  }

  /// The cache as a refresh leaves it on a feed: by default the 2026-11-01 Splatfest's, its
  /// Splatfest completed with its art address from `festivals.json`.
  private func snapshot(_ schedules: Fixture = .splatfestSecondHalf) async throws -> Snapshot {
    try await Snapshot(
      schedules: .init(content: ScheduleFeed.decode(from: schedules.data()), fetchTime: clock.now),
      festivals: .init(content: FestivalFeed.decode(from: Fixture.festivals.data()), fetchTime: clock.now))
  }

  @Test
  func `The art downloads once and is reused on the next run`() async throws {
    let snapshot = try await snapshot()
    let splatfest = try #require(snapshot.splatfest)
    try transport.reply(to: #require(splatfest.artURL), with: .ok(art, etag: nil))

    let first = await makeClient().updateSplatfestArt(in: snapshot)
    let second = await makeClient().updateSplatfestArt(in: snapshot)

    #expect(transport.requests.count == 1)
    let stored = try #require(FeedCache(directory: directory).splatfestArt(for: splatfest.id))
    #expect(try Data(contentsOf: stored) == art)
    #expect(first == stored)
    #expect(second == stored)
  }

  @Test(arguments: [true, false])
  func `The art is removed once the Splatfest is over`(isStillNamed: Bool) async throws {
    let snapshot = try await snapshot()
    let splatfest = try #require(snapshot.splatfest)
    try transport.reply(to: #require(splatfest.artURL), with: .ok(art, etag: nil))
    let client = makeClient()
    _ = await client.updateSplatfestArt(in: snapshot)
    clock.now = splatfest.endTime

    let stored = try await client.updateSplatfestArt(in: isStillNamed ? snapshot : self.snapshot(.normalDay))

    #expect(stored == nil)
    #expect(client.cache.splatfestArt(for: splatfest.id) == nil)
    #expect(transport.requests.count == 1)
  }

  /// The feed decoded without its Splatfest, or not at all: either way it names no Splatfest.
  @Test(arguments: [true, false])
  func `A feed that cannot say which Splatfest is on leaves the art alone`(hasSchedules: Bool) async throws {
    let snapshot = try await snapshot()
    let splatfest = try #require(snapshot.splatfest)
    try transport.reply(to: #require(splatfest.artURL), with: .ok(art, etag: nil))
    let client = makeClient()
    _ = await client.updateSplatfestArt(in: snapshot)
    var unknown = snapshot
    if hasSchedules, let schedules = snapshot.schedules?.content {
      unknown.schedules?.content = ScheduleFeed(
        rotationsByMode: schedules.rotationsByMode,
        challenges: schedules.challenges,
        salmonRun: schedules.salmonRun,
        eggstraWork: schedules.eggstraWork,
        currentSplatfest: nil,
        terms: schedules.terms,
        failedSections: [.splatfest])
    }
    else {
      unknown.schedules = nil
    }

    _ = await client.updateSplatfestArt(in: unknown)

    #expect(client.cache.splatfestArt(for: splatfest.id) != nil)
  }

  @Test(arguments: [
    ScriptedTransport.Reply.status(503),
    .failure(URLError(.networkConnectionLost)),
    .ok(Data(), etag: nil),
  ])
  func `A failed download leaves no art`(_ reply: ScriptedTransport.Reply) async throws {
    let snapshot = try await snapshot()
    let splatfest = try #require(snapshot.splatfest)
    try transport.reply(to: #require(splatfest.artURL), with: reply)
    let client = makeClient()

    let stored = await client.updateSplatfestArt(in: snapshot)

    #expect(stored == nil)
    #expect(client.cache.splatfestArt(for: splatfest.id) == nil)
  }

  /// The art passes the feeds' gate: an answer closes it for an hour, no answer backs off.
  @Test(arguments: [
    (ScriptedTransport.Reply.status(503), FeedGate.interval),
    (.failure(URLError(.networkConnectionLost)), FeedGate.firstBackOff),
  ])
  func `A failed download is tried again only once the gate opens`(
    _ reply: ScriptedTransport.Reply,
    wait: Duration)
    async throws
  {
    let snapshot = try await snapshot()
    let splatfest = try #require(snapshot.splatfest)
    try transport.reply(to: #require(splatfest.artURL), with: reply)
    let client = makeClient()
    let start = clock.now

    _ = await client.updateSplatfestArt(in: snapshot)
    clock.now = start.addingTimeInterval(wait / .seconds(1) - 1)
    _ = await client.updateSplatfestArt(in: snapshot)
    let requestsWhileClosed = transport.requests.count
    clock.now = start.addingTimeInterval(wait / .seconds(1))
    _ = await client.updateSplatfestArt(in: snapshot)

    #expect(requestsWhileClosed == 1)
    #expect(transport.requests.count == 2)
  }

  @Test
  func `Art on any host but assets splatoon3 ink is never requested`() async throws {
    var snapshot = try await snapshot()
    let elsewhere =
      try #require(URL(string: "https://cdn-image-e0d67c509fb203858ebcb2fe3f88c2aa.baas.nintendo.com/1/a"))
    let id = try #require(snapshot.schedules?.content.currentSplatfest?.feedID)
    let record = try #require(snapshot.festivals?.content.records[id])
    snapshot.festivals?.content = FestivalFeed(records: [
      id: .init(id: record.id, title: record.title, teamNames: record.teamNames, artURL: elsewhere),
    ])
    transport.reply(to: elsewhere, with: .ok(art, etag: nil))
    let client = makeClient()

    let stored = await client.updateSplatfestArt(in: snapshot)

    #expect(transport.requests.isEmpty)
    #expect(stored == nil)
  }
}
