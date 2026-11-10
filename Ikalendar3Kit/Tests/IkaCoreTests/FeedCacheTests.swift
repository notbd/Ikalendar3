//
//  FeedCacheTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - FeedCacheTests

/// The cache as other processes see it: one directory, read by fresh instances at any moment.
final class FeedCacheTests {
  private let directory: URL

  init() throws {
    directory = try makeTestDirectory()
  }

  deinit {
    try? FileManager.default.removeItem(at: directory)
  }

  @Test
  func `A fresh cache on the same directory reads every stored feed into a snapshot, none stale`()
    async throws
  {
    let transport: ScriptedTransport = .init()
    let replies: [(Feed, Fixture)] = [
      (.schedules, .splatfestSecondHalf),
      (.festivals, .festivals),
      (.locale(.enUS), .localeEnUS),
      (.locale(.jaJP), .localeJaJP),
    ]
    for (feed, fixture) in replies {
      try transport.reply(to: feed.url, with: .ok(fixture.data(), etag: #""\#(fixture)""#))
    }
    let writer: FeedClient = .init(
      transport: transport,
      cache: FeedCache(directory: directory),
      appVersion: "1.0.0",
      now: { date("2026-11-01T05:23:00Z") })
    for (feed, _) in replies {
      _ = await writer.fetch(feed)
    }

    let snapshot = await FeedCache(directory: directory).snapshot()

    let fetchTime = date("2026-11-01T05:23:00Z")
    #expect(try await snapshot == Snapshot(
      schedules: .init(content: ScheduleFeed.decode(from: Fixture.splatfestSecondHalf.data()), fetchTime: fetchTime),
      festivals: .init(content: FestivalFeed.decode(from: Fixture.festivals.data()), fetchTime: fetchTime),
      locales: [
        .enUS: .init(content: TermTable.decode(from: Fixture.localeEnUS.data()), fetchTime: fetchTime),
        .jaJP: .init(content: TermTable.decode(from: Fixture.localeJaJP.data()), fetchTime: fetchTime),
      ]))
    #expect(snapshot.schedules?.isStale == false)
    #expect(snapshot.festivals?.isStale == false)
    #expect(snapshot.locales.values.allSatisfy { !$0.isStale })
  }

  /// Views that render on the spot, such as a Live Activity's, read names without a snapshot.
  @Test
  func `Names read on the spot come from the cached locale file first, then the shipped snapshot`() throws {
    let scorchGorge: StageID = .init("VnNTdGFnZS0x")
    let eeltailAlley: StageID = .init("VnNTdGFnZS0y")
    let cache: FeedCache = .init(directory: directory)
    let localeFile: Data = .init(#"{"stages": {"VnNTdGFnZS0x": {"name": "Gorge (cached)"}}}"#.utf8)

    #expect(cache.terms(in: .enUS).name(of: scorchGorge) == "Scorch Gorge")

    try cache.commit(
      FeedRecord(body: localeFile, etag: nil, fetchTime: date("2026-11-01T05:23:00Z")),
      for: .locale(.enUS))

    let terms = cache.terms(in: .enUS)
    #expect(terms.language == .enUS)
    #expect(terms.name(of: scorchGorge) == "Gorge (cached)")
    #expect(terms.name(of: eeltailAlley) == "Eeltail Alley")
    #expect(cache.terms(in: .jaJP).name(of: scorchGorge) == "ユノハナ大渓谷")
  }

  @Test
  func `An empty directory reads as an empty snapshot`() async {
    #expect(await FeedCache(directory: directory).snapshot() == Snapshot())
  }

  /// A reader at any moment of a commit stands in for a reader at the moment a writer is killed:
  /// it sees the previous record or the new one, whole, never a torn file or a mix of the two.
  @Test
  func `A read during commits always returns one whole record`() async throws {
    let cache: FeedCache = .init(directory: directory)
    let records = [
      FeedRecord(body: Data(repeating: 0xA, count: 600_000), etag: #""a""#, fetchTime: date("2026-10-20T12:00:00Z")),
      FeedRecord(body: Data(repeating: 0xB, count: 400_000), etag: #"W/"b""#, fetchTime: date("2026-10-20T13:00:00Z")),
    ]
    try cache.commit(records[0], for: .schedules)

    async let writes: Void = {
      for index in 1 ... 300 {
        try? cache.commit(records[index % 2], for: .schedules)
      }
    }()
    async let reads = {
      (1 ... 300).map { _ in cache.record(for: .schedules) }
    }()

    await writes
    let seen = await reads
    #expect(seen.allSatisfy { $0.map(records.contains) == true })
  }
}
