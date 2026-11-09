//
//  FixtureLaunch.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - FixtureLaunch

/// A Debug launch on recorded payloads instead of the network, for screenshots, recordings and
/// boundary checks. The app and the watch app read it from their launch arguments:
///
/// ```
/// --fixture normalDay                     the recorded schedules feed, by its `Fixture` case
/// --fixture-folder <Ikalendar3Kit/Fixtures>   where the payloads are read, so no product ships them
/// --fixture-instant 2026-10-20T13:59:50Z      the instant the clock starts at
/// --fixture-rebase                        optional: move the payloads to now instead
/// ```
///
/// The schedules feed comes with the recorded `festivals.json` and every recorded locale file.
public struct FixtureLaunch: Hashable, Sendable {
  /// The recorded schedules feed.
  public let schedules: Fixture
  /// The folder the payloads are read from: the package's `Fixtures` folder.
  public let folder: URL
  /// The instant the clock starts at, or the instant a rebase moves to now.
  public let instant: Date
  /// Whether the payloads move to now and land in the shared cache, so the Surfaces the system
  /// renders on its own clock (widgets, the Live Activity) show the fixture day too.
  public let isRebased: Bool

  /// A fixture launch with the given parts.
  public init(schedules: Fixture, folder: URL, instant: Date, isRebased: Bool) {
    self.schedules = schedules
    self.folder = folder
    self.instant = instant
    self.isRebased = isRebased
  }

  /// The fixture launch a process's arguments ask for, or `nil` when they have no `--fixture`.
  ///
  /// - Throws: `OptionError` when an option is missing or malformed: a launch that asked for
  ///   fixtures never falls back to the network.
  public init?(arguments: [String]) throws(OptionError) {
    let arguments: LaunchArguments = .init(arguments)
    guard arguments.contains(Option.fixture) else { return nil }

    let name = try arguments.required(Option.fixture)
    guard let schedules = Fixture.allCases.first(where: { name == "\($0)" && $0.feed == .schedules }) else {
      throw .unknownFixture(name)
    }

    let folder = try arguments.required(Option.folder)
    let instantText = try arguments.required(Option.instant)
    guard let instant = try? Date(instantText, strategy: .iso8601) else { throw .malformedInstant(instantText) }

    self.init(
      schedules: schedules,
      folder: URL(filePath: folder, directoryHint: .isDirectory),
      instant: instant,
      isRebased: arguments.contains(Option.rebase))
  }

  /// The option names.
  private enum Option {
    static let fixture = "--fixture"
    static let folder = "--fixture-folder"
    static let instant = "--fixture-instant"
    static let rebase = "--fixture-rebase"
  }
}

// MARK: FixtureLaunch.OptionError

extension FixtureLaunch {
  /// Why a fixture launch's arguments were refused.
  public enum OptionError: Error, Hashable, Sendable {
    /// An option that needs a value has none.
    case missing(String)
    /// `--fixture` names no recorded schedules feed.
    case unknownFixture(String)
    /// `--fixture-instant` is not an ISO 8601 UTC instant.
    case malformedInstant(String)
  }
}

// MARK: - LaunchArguments

/// A process's launch arguments, read as `--name value` options and `--name` flags.
public struct LaunchArguments: Sendable {
  private let arguments: [String]

  /// The arguments as the process received them, its path first.
  public init(_ arguments: [String] = ProcessInfo.processInfo.arguments) {
    self.arguments = arguments
  }

  /// Whether the option or flag is present.
  public func contains(_ name: String) -> Bool {
    arguments.dropFirst().contains(name)
  }

  /// The value after an option, or `nil` when the option is absent or ends the arguments.
  public func value(of name: String) -> String? {
    guard let index = arguments.dropFirst().firstIndex(of: name) else { return nil }

    return arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
  }

  /// The value after an option.
  func required(_ name: String) throws(FixtureLaunch.OptionError) -> String {
    guard let value = value(of: name) else { throw .missing(name) }

    return value
  }
}

// MARK: - Fixture + Feed

extension Fixture {
  /// The feed the payload answers, read from its file name: `schedules-…`, `festivals-…` or
  /// `locale-<date>-<code>.json`.
  var feed: Feed? {
    if rawValue.hasPrefix("schedules-") { return .schedules }
    if rawValue.hasPrefix("festivals-") { return .festivals }
    return GameLanguage.allCases
      .first { rawValue.hasPrefix("locale-") && rawValue.hasSuffix("-\($0.rawValue).json") }
      .map(Feed.locale)
  }
}

// MARK: - FixtureRun

/// What a fixture launch runs on: the feed client to build the refresh engine on and the time
/// source to build the app clock on.
public struct FixtureRun: Sendable {
  /// A client whose scripted transport answers every feed from the payloads.
  public let client: FeedClient
  /// The clock: running from the instant, or the system's for a rebased launch.
  public let timeSource: any TimeSource
}

extension FixtureLaunch {
  /// The cache folder of an unrebased launch: one fixed folder in the temporary directory, wiped
  /// at each launch, so launches leave no folder behind.
  static let unrebasedCacheDirectory: URL = FileManager.default.temporaryDirectory.appending(
    path: "ikalendar3-fixture",
    directoryHint: .isDirectory)

  /// Reads the payloads and builds the run.
  ///
  /// - An unrebased launch keeps the payloads as recorded in `unrebasedCacheDirectory`, which it
  ///   wipes first, and starts its clock at the instant: the shared cache stays untouched.
  /// - A rebased launch moves the payloads by `now` minus the instant and commits them to
  ///   `sharedCache` before anything reads it, then runs on the system's clock.
  ///
  /// The transport answers a locale file with no recording with an empty one, so that text set's
  /// names come from the shipped snapshot and its refresh does not fail.
  ///
  /// - Parameters:
  ///   - sharedCache: The cache every process on the device reads: the App Group's, or the
  ///     worktree's on a Mac.
  ///   - now: The wall clock at launch.
  public func prepare(sharedCache: FeedCache, now: Date) throws -> FixtureRun {
    let offset: Duration = .seconds(now.timeIntervalSince(instant).rounded(.towardZero))
    var payloads: [Feed: Data] = [:]
    for fixture in [schedules, .festivals] + Fixture.allCases.filter({ $0.rawValue.hasPrefix("locale-") }) {
      guard let feed = fixture.feed else { continue }

      let recorded = try fixture.data(in: folder)
      payloads[feed] = isRebased ? Fixture.rebase(recorded, by: offset) : recorded
    }

    let transport: ScriptedTransport = .init()
    for language in GameLanguage.allCases where payloads[.locale(language)] == nil {
      transport.reply(to: Feed.locale(language).url, with: .ok(Data("{}".utf8), etag: nil))
    }
    for (feed, payload) in payloads {
      transport.reply(to: feed.url, with: .ok(payload, etag: nil))
    }

    guard isRebased else {
      let clock: RunningClock = .init(startingAt: instant)
      let directory: URL = Self.unrebasedCacheDirectory
      try? FileManager.default.removeItem(at: directory)
      let client: FeedClient = .init(transport: transport, cache: FeedCache(directory: directory), now: { clock.now })
      return FixtureRun(client: client, timeSource: clock)
    }

    for (feed, payload) in payloads {
      try sharedCache.commit(FeedRecord(body: payload, etag: nil, fetchTime: now), for: feed)
    }
    return FixtureRun(client: FeedClient(transport: transport, cache: sharedCache), timeSource: SystemTimeSource())
  }
}
