//
//  FixtureLaunchTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import Testing
@testable import IkaFixtures

// MARK: - FixtureLaunchTests

/// The Debug fixture launch: which recorded payloads a process runs on, from which instant, and
/// where they land. Serialized: unrebased launches share one temporary folder.
@MainActor
@Suite(.serialized)
final class FixtureLaunchTests {
  /// Stands in for the App Group container's feed folder.
  private let sharedDirectory: URL

  init() throws {
    sharedDirectory = try makeTestDirectory()
  }

  deinit {
    try? FileManager.default.removeItem(at: sharedDirectory)
  }

  /// A launch on the normal day at 13:15 UTC.
  private func launch(isRebased: Bool) -> FixtureLaunch {
    FixtureLaunch(
      schedules: .normalDay,
      folder: Fixture.folder,
      instant: date("2026-10-20T13:15:00Z"),
      isRebased: isRebased)
  }

  /// The normal day's Anarchy Series screen at the launch instant, decoded straight from the file.
  private func recordedScreen() async throws -> BattleScreen? {
    try await Snapshot.schedules(.normalDay).battleScreen(of: .anarchySeries, at: date("2026-10-20T13:15:00Z"))
  }

  // MARK: Arguments

  @Test
  func `A launch without the fixture option is no fixture launch`() throws {
    #expect(try FixtureLaunch(arguments: ["/app", "-AppleLanguages", "(de)", "--fixture-rebase"]) == nil)
  }

  @Test
  func `A fixture launch reads the named schedules, the folder, the instant and the rebase flag`() throws {
    let launch = try FixtureLaunch(arguments: [
      "/app",
      "--fixture", "normalDay",
      "--fixture-folder", "/tmp/Fixtures",
      "--fixture-instant", "2026-10-20T13:59:50Z",
      "--fixture-rebase",
    ])

    #expect(launch == FixtureLaunch(
      schedules: .normalDay,
      folder: URL(filePath: "/tmp/Fixtures", directoryHint: .isDirectory),
      instant: date("2026-10-20T13:59:50Z"),
      isRebased: true))
  }

  @Test(arguments: [
    ("regularBattle", Mode.battle(.regular)),
    ("anarchySeries", .battle(.anarchySeries)),
    ("anarchyOpen", .battle(.anarchyOpen)),
    ("xBattle", .battle(.x)),
    ("salmonRun", .salmonRun),
  ])
  func `A fixture launch reads the Mode its short-item Tracking follows`(name: String, mode: Mode) throws {
    let launch = try FixtureLaunch(arguments: [
      "/app",
      "--fixture", "normalDay",
      "--fixture-folder", "/tmp/Fixtures",
      "--fixture-instant", "2026-10-20T13:59:50Z",
      "--fixture-short-tracking", name,
    ])

    #expect(launch?.shortTracking == mode)
    #expect(try FixtureLaunch(arguments: [
      "/app",
      "--fixture",
      "normalDay",
      "--fixture-folder",
      "/f",
      "--fixture-instant",
      "2026-10-20T12:00:00Z",
    ])?.shortTracking == nil)
  }

  @Test(arguments: [
    (
      ["--fixture", "someDay", "--fixture-folder", "/f", "--fixture-instant", "2026-10-20T12:00:00Z"],
      FixtureLaunch.OptionError.unknownFixture("someDay")),
    (
      ["--fixture", "festivals", "--fixture-folder", "/f", "--fixture-instant", "2026-10-20T12:00:00Z"],
      .unknownFixture("festivals")),
    (["--fixture", "normalDay", "--fixture-instant", "2026-10-20T12:00:00Z"], .missing("--fixture-folder")),
    (["--fixture", "normalDay", "--fixture-folder", "/f"], .missing("--fixture-instant")),
    (["--fixture", "normalDay", "--fixture-folder", "/f", "--fixture-instant", "noon"], .malformedInstant("noon")),
    (["--fixture"], .missing("--fixture")),
    (
      [
        "--fixture",
        "normalDay",
        "--fixture-folder",
        "/f",
        "--fixture-instant",
        "2026-10-20T12:00:00Z",
        "--fixture-short-tracking",
        "splatfestBattle",
      ],
      .unknownMode("splatfestBattle")),
  ])
  func `A fixture launch with a missing or malformed option is refused`(
    arguments: [String],
    error: FixtureLaunch.OptionError)
  {
    #expect(throws: error) { try FixtureLaunch(arguments: ["/app"] + arguments) }
  }

  // MARK: Runs

  @Test
  func `An unrebased fixture launch refreshes from the recordings on a clock running from the instant`() async throws {
    let run = try launch(isRebased: false).prepare(sharedCache: FeedCache(directory: sharedDirectory), now: Date())
    // German has no recorded locale file: its names come from the shipped snapshot, with no failure.
    let engine: RefreshEngine = .init(client: run.client, language: .deDE)

    let result = await engine.refresh()

    let now = run.timeSource.now
    #expect(now >= date("2026-10-20T13:15:00Z") && now < date("2026-10-20T13:15:10Z"))
    #expect(engine.status == .loaded)
    #expect(Set(result.outcomes.values) == [.fetched(.updated)])
    let screen = engine.snapshot.battleScreen(of: .anarchySeries, at: date("2026-10-20T13:15:00Z"))
    #expect(try await screen?.current == recordedScreen()?.current)
    #expect(
      try FileManager.default.contentsOfDirectory(atPath: sharedDirectory.path()).isEmpty,
      "the shared cache is untouched")
  }

  /// Council round 5, M10: launches leave no folder behind.
  @Test
  func `An unrebased fixture launch keeps its cache in one temporary folder, wiped at start`() async throws {
    let folder: URL = FixtureLaunch.unrebasedCacheDirectory
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let leftover = folder.appending(path: "leftover")
    try Data().write(to: leftover)

    let run = try launch(isRebased: false).prepare(sharedCache: FeedCache(directory: sharedDirectory), now: Date())
    await RefreshEngine(client: run.client, language: .enUS).refresh()

    #expect(!FileManager.default.fileExists(atPath: leftover.path()))
    #expect(await FeedCache(directory: folder).snapshot().schedules != nil)
  }

  @Test
  func `A rebased fixture launch commits the payloads moved to now to the shared cache`() async throws {
    let now: Date = .init()
    let shared: FeedCache = .init(directory: sharedDirectory)

    let run = try launch(isRebased: true).prepare(sharedCache: shared, now: now)

    #expect(abs(run.timeSource.now.timeIntervalSince(Date())) < 1, "a rebased launch runs on the system clock")
    let snapshot = await shared.snapshot()
    #expect(snapshot.festivals != nil)
    #expect(snapshot.locales.keys.contains(.jaJP))
    guard
      case .running(let recorded) = try await recordedScreen()?.current,
      case .running(let moved) = snapshot.battleScreen(of: .anarchySeries, at: now)?.current
    else {
      Issue.record("no current Rotation in the recorded or the rebased schedules")
      return
    }

    #expect(moved.item.setting == recorded.item.setting)
    let offset = moved.item.startTime.timeIntervalSince(recorded.item.startTime)
    #expect(abs(offset - now.timeIntervalSince(date("2026-10-20T13:15:00Z"))) < 1)
  }

  // MARK: Short-item Tracking

  /// A recording crosses two boundaries in four minutes instead of hours.
  /// Salmon Run's instant puts the Big Run third.
  @Test(arguments: [(Mode.battle(.anarchyOpen), "2026-09-07T12:00:00Z"), (.salmonRun, "2026-09-09T12:00:00Z")])
  func `Short-item Tracking keeps the carried ids and makes each item two minutes long from the start`(
    mode: Mode,
    instant: String)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.bigRun.data())
    let content = feed.trackingContent(of: mode, at: date(instant))
    let start = date("2026-11-09T10:00:00Z")

    let short = content.withShortItems(startingAt: start)

    #expect(short.mode == mode)
    #expect(short.staleDate == date("2026-11-09T10:02:00Z"))
    switch (content, short) {
      case (.battle(_, let rotations), .battle(_, let shortRotations)):
        #expect(shortRotations.map(\.setting) == rotations.map(\.setting))
        #expect(shortRotations.map(\.startTime) == ["10:00", "10:02", "10:04"].map { date("2026-11-09T\($0):00Z") })
        #expect(shortRotations.map(\.endTime) == ["10:02", "10:04", "10:06"].map { date("2026-11-09T\($0):00Z") })

      case (.salmonRun(let shifts), .salmonRun(let shortShifts)):
        #expect(shortShifts.map(\.stage) == shifts.map(\.stage))
        #expect(shortShifts.map(\.weapons) == shifts.map(\.weapons))
        #expect(shortShifts.map(\.isBigRun) == [false, false, true])
        #expect(shortShifts.map(\.endTime) == ["10:02", "10:04", "10:06"].map { date("2026-11-09T\($0):00Z") })

      default:
        Issue.record("short-item Tracking changed the Mode")
    }
  }

  @Test
  func `A running clock starts at its instant and runs at real speed`() async throws {
    let start = date("2026-10-20T13:59:59Z")
    let clock: RunningClock = .init(startingAt: start)

    #expect(clock.now.timeIntervalSince(start) < 0.5)
    try await clock.sleep(until: start.addingTimeInterval(0.2))
    #expect(clock.now >= start.addingTimeInterval(0.2))
  }
}
