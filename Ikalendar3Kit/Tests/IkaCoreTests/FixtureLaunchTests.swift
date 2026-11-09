//
//  FixtureLaunchTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing

// MARK: - FixtureLaunchTests

/// The Debug fixture launch: which recorded payloads a process runs on, from which instant, and
/// where they land.
@MainActor
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

  @Test
  func `A running clock starts at its instant and runs at real speed`() async throws {
    let start = date("2026-10-20T13:59:59Z")
    let clock: RunningClock = .init(startingAt: start)

    #expect(clock.now.timeIntervalSince(start) < 0.5)
    try await clock.sleep(until: start.addingTimeInterval(0.2))
    #expect(clock.now >= start.addingTimeInterval(0.2))
  }
}
