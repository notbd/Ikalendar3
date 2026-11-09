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

  /// The 2026-11-01 Splatfest, completed with its art address from `festivals.json`.
  private func splatfest() async throws -> Splatfest {
    let snapshot = try await Snapshot(
      schedules: .init(content: ScheduleFeed.decode(from: Fixture.splatfestSecondHalf.data()), fetchTime: clock.now),
      festivals: .init(content: FestivalFeed.decode(from: Fixture.festivals.data()), fetchTime: clock.now))
    return try #require(snapshot.splatfest)
  }

  @Test
  func `The art downloads once and is reused on the next run`() async throws {
    let splatfest = try await splatfest()
    try transport.reply(to: #require(splatfest.artURL), with: .ok(art, etag: nil))

    await makeClient().updateSplatfestArt(for: splatfest)
    await makeClient().updateSplatfestArt(for: splatfest)

    #expect(transport.requests.count == 1)
    let stored = try #require(FeedCache(directory: directory).splatfestArt(for: splatfest.id))
    #expect(try Data(contentsOf: stored) == art)
  }

  @Test(arguments: [true, false])
  func `The art is removed once the Splatfest is over`(isStillNamed: Bool) async throws {
    let splatfest = try await splatfest()
    try transport.reply(to: #require(splatfest.artURL), with: .ok(art, etag: nil))
    let client = makeClient()
    await client.updateSplatfestArt(for: splatfest)
    clock.now = splatfest.endTime

    await client.updateSplatfestArt(for: isStillNamed ? splatfest : nil)

    #expect(client.cache.splatfestArt(for: splatfest.id) == nil)
    #expect(transport.requests.count == 1)
  }

  @Test(arguments: [
    ScriptedTransport.Reply.status(503),
    .failure(URLError(.networkConnectionLost)),
    .ok(Data(), etag: nil),
  ])
  func `A failed download leaves no art`(_ reply: ScriptedTransport.Reply) async throws {
    let splatfest = try await splatfest()
    try transport.reply(to: #require(splatfest.artURL), with: reply)
    let client = makeClient()

    await client.updateSplatfestArt(for: splatfest)

    #expect(client.cache.splatfestArt(for: splatfest.id) == nil)
  }

  @Test
  func `Art on any host but assets splatoon3 ink is never requested`() async throws {
    var splatfest = try await splatfest()
    let elsewhere =
      try #require(URL(string: "https://cdn-image-e0d67c509fb203858ebcb2fe3f88c2aa.baas.nintendo.com/1/a"))
    splatfest.artURL = elsewhere
    transport.reply(to: elsewhere, with: .ok(art, etag: nil))
    let client = makeClient()

    await client.updateSplatfestArt(for: splatfest)

    #expect(transport.requests.isEmpty)
    #expect(client.cache.splatfestArt(for: splatfest.id) == nil)
  }
}
