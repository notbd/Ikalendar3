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
/// where they land.
@MainActor
final class FixtureLaunchTests {
  /// Stands in for the App Group container's feed folder.
  private let sharedDirectory: URL
  /// Stands in for the process's temporary directory, which every process of the user shares on
  /// a Mac.
  private let temporaryDirectory: URL

  init() throws {
    sharedDirectory = try makeTestDirectory()
    temporaryDirectory = try makeTestDirectory()
  }

  deinit {
    try? FileManager.default.removeItem(at: sharedDirectory)
    try? FileManager.default.removeItem(at: temporaryDirectory)
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

  @Test
  func `A fixture launch reads the time zone its times are written in`() throws {
    let launch = try FixtureLaunch(arguments: [
      "/app",
      "--fixture", "bigRun",
      "--fixture-folder", "/tmp/Fixtures",
      "--fixture-instant", "2026-09-07T12:00:00Z",
      "--fixture-time-zone", "Asia/Tokyo",
    ])

    #expect(launch?.timeZone == TimeZone(identifier: "Asia/Tokyo"))
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
        "--fixture", "normalDay", "--fixture-folder", "/f", "--fixture-instant", "2026-10-20T12:00:00Z",
        "--fixture-time-zone", "Mars/Olympus",
      ],
      .unknownTimeZone("Mars/Olympus")),
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
    let run = try launch(isRebased: false).prepare(
      sharedCache: FeedCache(directory: sharedDirectory),
      temporaryDirectory: temporaryDirectory,
      now: Date())
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

  /// No two processes share a cache folder (launches from two worktrees, or one during the
  /// package tests), and launches leave no folder behind for long: each removes the ones of ended
  /// processes.
  @Test
  func `An unrebased fixture launch keeps its cache in its own process's folder and removes ended processes' folders`()
    async throws
  {
    let fileManager: FileManager = .default
    func folder(_ name: String) throws -> URL {
      let folder = temporaryDirectory.appending(path: name, directoryHint: .isDirectory)
      try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
      try Data().write(to: folder.appending(path: "leftover"))
      return folder
    }
    let own = try folder("ikalendar3-fixture-\(getpid())")
    // No process has an id this high; launchd's is 1 and runs.
    let ended = try folder("ikalendar3-fixture-\(Int32.max)")
    let running = try folder("ikalendar3-fixture-1")
    let unrelated = try folder("ikalendar3-other")

    let run = try launch(isRebased: false).prepare(
      sharedCache: FeedCache(directory: sharedDirectory),
      temporaryDirectory: temporaryDirectory,
      now: Date())
    await RefreshEngine(client: run.client, language: .enUS).refresh()

    #expect(!fileManager.fileExists(atPath: own.appending(path: "leftover").path()), "wiped at start")
    #expect(await FeedCache(directory: own).snapshot().schedules != nil)
    #expect(!fileManager.fileExists(atPath: ended.path()))
    #expect(fileManager.fileExists(atPath: running.appending(path: "leftover").path()))
    #expect(fileManager.fileExists(atPath: unrelated.appending(path: "leftover").path()))
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

  /// Screenshots taken at any hour show the clock times of the recording: the payloads move by
  /// whole hours, and the time zone takes up the rest of the day.
  @Test
  func `A rebased fixture launch with a time zone moves by whole hours and reads each time as the recording does`()
    async throws
  {
    let instant = date("2026-10-20T13:15:00Z")
    let now = instant.addingTimeInterval(5 * 3600 + 23 * 60 + 10)
    let tokyo: TimeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
    let shared: FeedCache = .init(directory: sharedDirectory)
    let launch: FixtureLaunch = .init(
      schedules: .normalDay,
      folder: Fixture.folder,
      instant: instant,
      isRebased: true,
      timeZone: tokyo)

    let run = try launch.prepare(sharedCache: shared, now: now)

    guard
      case .running(let recorded) = try await recordedScreen()?.current,
      case .running(let moved) = await shared.snapshot().battleScreen(of: .anarchySeries, at: now)?.current
    else {
      Issue.record("no current Rotation in the recorded or the rebased schedules")
      return
    }

    #expect(moved.item.startTime.timeIntervalSince(recorded.item.startTime) == 5 * 3600)
    let zone = try #require(run.timeZone)
    func hour(_ time: Date, in zone: TimeZone) -> Int {
      var calendar: Calendar = .init(identifier: .gregorian)
      calendar.timeZone = zone
      return calendar.component(.hour, from: time)
    }
    #expect(hour(moved.item.startTime, in: zone) == hour(recorded.item.startTime, in: tokyo))
    #expect(hour(moved.item.endTime, in: zone) == hour(recorded.item.endTime, in: tokyo))
  }

  @Test
  func `An unrebased fixture launch with a time zone reads times in that zone`() throws {
    let tokyo: TimeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
    let launch: FixtureLaunch = .init(
      schedules: .normalDay,
      folder: Fixture.folder,
      instant: date("2026-10-20T13:15:00Z"),
      isRebased: false,
      timeZone: tokyo)

    let run = try launch.prepare(
      sharedCache: FeedCache(directory: sharedDirectory),
      temporaryDirectory: temporaryDirectory,
      now: Date())

    #expect(run.timeZone == tokyo)
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
