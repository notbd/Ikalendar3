//
//  SplatfestDecodingTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CryptoKit
import Foundation
import Testing
@testable import IkaCore

struct SplatfestDecodingTests {
  /// A snapshot of a schedules fixture, with `festivals.json` unless left out.
  static private func snapshot(_ schedules: Fixture, withFestivals: Bool = true) async throws -> Snapshot {
    let fetchTime = date("2026-11-01T05:23:00Z")
    return try await Snapshot(
      schedules: .init(content: ScheduleFeed.decode(from: schedules.data()), fetchTime: fetchTime),
      festivals: withFestivals
        ? .init(content: FestivalFeed.decode(from: Fixture.festivals.data()), fetchTime: fetchTime)
        : nil)
  }

  @Test
  func `A running Splatfest combines the schedules feed with its festivals record`() async throws {
    let splatfest = try #require(try await Self.snapshot(.splatfestSecondHalf).splatfest)

    #expect(splatfest.id == SplatfestID("JUEA-00108"))
    #expect(splatfest.startTime == date("2026-10-31T00:00:00Z"))
    #expect(splatfest.midtermTime == date("2026-11-01T00:00:00Z"))
    #expect(splatfest.endTime == date("2026-11-02T00:00:00Z"))
    #expect(splatfest.teamColors == [
      RGBAColor(red: 0.0470600016, green: 0.639219999, blue: 0.294117659, alpha: 1),
      RGBAColor(red: 0.690196097, green: 0.309799999, blue: 0.137250006, alpha: 1),
      RGBAColor(red: 0.586669981, green: 0.286269993, blue: 0.586669981, alpha: 1),
    ])
    #expect(splatfest.tricolorStages == [StageID("VnNTdGFnZS0x"), StageID("VnNTdGFnZS02")])
    #expect(splatfest.artURL == URL(
      string: "https://assets.splatoon3.ink/splatnet/resources/fest/v1/juea-maple2/"
        + "46bccd11c2905095a8cd5cb9e7457ed54856282a9d5123e74f3ca071cf17bd4e_0.png"))
  }

  @Test
  func `A Splatfest in its last hours finds its own festivals record among older ones`() async throws {
    let splatfest = try #require(try await Self.snapshot(.splatfestEnd).splatfest)

    #expect(splatfest.id == SplatfestID("JUEA-00107"))
    #expect(splatfest.startTime == date("2026-08-22T00:00:00Z"))
    #expect(splatfest.midtermTime == date("2026-08-23T00:00:00Z"))
    #expect(splatfest.endTime == date("2026-08-24T00:00:00Z"))
    #expect(splatfest.teamColors == [
      RGBAColor(red: 0.913999975, green: 0.934000015, blue: 0.224000007, alpha: 1),
      RGBAColor(red: 0.192000002, green: 0.698000014, blue: 0.913999975, alpha: 1),
      RGBAColor(red: 0.859000027, green: 0.195999995, blue: 0.906000018, alpha: 1),
    ])
    #expect(splatfest.tricolorStages == [StageID("VnNTdGFnZS04"), StageID("VnNTdGFnZS0xOA==")])
    #expect(splatfest.artURL?.pathComponents.contains("juea-sweat") == true)
  }

  @Test
  func `Without festivals json the Splatfest still decodes, without art`() async throws {
    let splatfest = try #require(try await Self.snapshot(.splatfestSecondHalf, withFestivals: false).splatfest)

    #expect(splatfest.id == SplatfestID("JUEA-00108"))
    #expect(splatfest.artURL == nil)
  }

  @Test
  func `A malformed region of festivals json leaves the other regions' records intact`() async throws {
    var regions = try #require(try JSONSerialization.jsonObject(with: Fixture.festivals.data()) as? [String: Any])
    regions["EU"] = 42
    let festivals = try await FestivalFeed.decode(from: JSONSerialization.data(withJSONObject: regions))
    let schedules = try await ScheduleFeed.decode(from: Fixture.splatfestSecondHalf.data())
    let fetchTime = date("2026-11-01T05:23:00Z")

    let snapshot: Snapshot = .init(
      schedules: .init(content: schedules, fetchTime: fetchTime),
      festivals: .init(content: festivals, fetchTime: fetchTime))

    #expect(snapshot.splatfest?.artURL != nil)
    #expect(snapshot.feedTerms.splatfests[SplatfestID("JUEA-00108")]?.teamNames == ["Wizard", "Knight", "Ninja"])
  }

  @Test
  func `A body in which no region decodes is not festivals json`() async {
    await #expect(throws: DecodingError.self) {
      try await FestivalFeed.decode(from: Data(#"{"errors": []}"#.utf8))
    }
  }

  @Test
  func `A normal day has no Splatfest`() async throws {
    #expect(try await Self.snapshot(.normalDay).splatfest == nil)
  }

  // MARK: - Archive snapshots

  @Test(arguments: [
    (Fixture.splatfestAnnounced, "b240043ff484e0f3133ea5bfbf9b6a5493c62a46775b0f5caa69afb204427682"),
    (Fixture.splatfestFirstHalf, "f8efdf553c4d80cb44bd0bc7f390df989ad3ec950a7812ca258e46884c475aa0"),
  ])
  func `Archive snapshots match their SHA-256`(_ fixture: Fixture, sha256: String) throws {
    let digest = try SHA256.hash(data: fixture.data())
    #expect(digest.map { String(format: "%02x", $0) }.joined() == sha256)
  }

  @Test
  func `Before its start the announced Splatfest decodes and battles run until it starts`() async throws {
    let snapshot = try await Self.snapshot(.splatfestAnnounced)
    let recorded = date("2026-10-30T12:00:00Z")

    let splatfest = try #require(snapshot.splatfest)
    #expect(splatfest.id == SplatfestID("JUEA-00108"))
    #expect(splatfest.startTime == date("2026-10-31T00:00:00Z"))
    #expect(recorded < splatfest.startTime)

    let feed = try #require(snapshot.schedules?.content)
    let splatfestStartTimes = feed.rotations(for: .splatfestBattle(.open)).map(\.startTime)
    for mode in BattleMode.allCases {
      let rotations = feed.rotations(for: .battle(mode))
      let lastPlayed = rotations.last { !$0.isPaused }
      let pausedStartTimes = rotations.filter(\.isPaused).map(\.startTime)
      #expect(lastPlayed?.endTime == splatfest.startTime, "\(mode)")
      #expect(pausedStartTimes == splatfestStartTimes, "\(mode)")
    }
    #expect(feed.rotations(for: .splatfestBattle(.open)).first?.startTime == splatfest.startTime)
    #expect(feed.rotations(for: .splatfestBattle(.pro)).count == 6)
  }

  @Test
  func `In its first half the Splatfest pauses every continuous Battle Mode`() async throws {
    let snapshot = try await Self.snapshot(.splatfestFirstHalf)
    let recorded = date("2026-10-31T12:00:00Z")

    let splatfest = try #require(snapshot.splatfest)
    #expect(splatfest.id == SplatfestID("JUEA-00108"))
    #expect(splatfest.startTime <= recorded && recorded < splatfest.midtermTime)
    #expect(splatfest.tricolorStages == [StageID("VnNTdGFnZS0x"), StageID("VnNTdGFnZS02")])

    let feed = try #require(snapshot.schedules?.content)
    for mode in BattleMode.allCases {
      let rotations = feed.rotations(for: .battle(mode))
      let pausedCount = rotations.count { $0.isPaused }
      #expect(rotations.count == 12, "\(mode)")
      #expect(pausedCount == 12, "\(mode)")
    }
    #expect(feed.rotations(for: .splatfestBattle(.open)).count == 12)
    #expect(feed.rotations(for: .splatfestBattle(.pro)).count == 12)
  }
}
