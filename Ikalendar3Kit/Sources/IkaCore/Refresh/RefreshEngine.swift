//
//  RefreshEngine.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Observation

// MARK: - RefreshEngine

/// The one engine every entry point refreshes through: app opening, pull to refresh, the toolbar
/// button, the Live Activity's Refresh button, Siri and background tasks.
///
/// Each refresh publishes the cache first, so content shows at once and offline, then passes each
/// feed through the shared `FeedGate`, then publishes the cache again. A failed feed keeps its
/// last good data and is marked stale; nothing a refresh does blanks content already shown. As
/// in ikalendar 2, the in-flight `status` is kept apart from the `settledStatus` a screen shows.
///
/// Surfaces observe it on the main actor; requests, decoding and file access run off it.
@MainActor
@Observable
final public class RefreshEngine {
  /// The data every Surface shows: the cache as the last refresh read it, with this engine's
  /// stale marks.
  private(set) public var snapshot: Snapshot = .init()
  /// Whether a refresh is in flight, and how the last one ended. `.loading` until the first
  /// refresh ends.
  private(set) public var status: RefreshStatus = .loading
  /// How the last refresh ended: `status` without its `.loading` phases, so a screen that shows
  /// the outcome keeps it on screen while the next refresh runs. `.loading` only until the first
  /// refresh ends.
  private(set) public var settledStatus: RefreshStatus = .loading

  @ObservationIgnored private let client: FeedClient
  @ObservationIgnored private let gate: FeedGate
  @ObservationIgnored private let feeds: [Feed]
  /// The refresh in flight, which a call arriving meanwhile joins.
  @ObservationIgnored private var inFlight: Task<RefreshResult, Never>?
  /// When each feed's last refresh in this engine failed, until its record is renewed.
  @ObservationIgnored private var failureTimes: [Feed: Date] = [:]

  /// An engine that refreshes through a client's cache directory, which its attempt records share.
  ///
  /// - Parameter language: The app language. Its locale file is the only one refreshed, under the
  ///   same hourly gate as the other feeds: term lookups read it first, and the shipped snapshot
  ///   covers the other text sets.
  public init(client: FeedClient, language: GameLanguage) {
    self.client = client
    gate = FeedGate(directory: client.cache.directory, lease: client.timeout, now: client.now)
    feeds = [.schedules, .festivals, .locale(language)]
  }

  /// Refreshes every feed and publishes the cache as the refresh left it. A call while a refresh
  /// is in flight joins it. The refresh runs to its end even if a caller is cancelled, because
  /// others may be waiting on it.
  @discardableResult
  public func refresh() async -> RefreshResult {
    if let inFlight { return await inFlight.value }

    // Cleared as the run ends, on this actor, so a later call starts a new refresh.
    let run = Task {
      defer { self.inFlight = nil }
      return await self.run()
    }
    inFlight = run
    return await run.value
  }

  /// One refresh: publishes the cache, passes each feed through the gate, publishes the cache as
  /// the feeds left it, and keeps the Splatfest art in step with it.
  ///
  /// The cache is reread at both ends because other engines commit to it at any moment. Every
  /// published value is `Equatable`, and `@Observable` publishes no value equal to the current
  /// one, so a status or snapshot that does not change is not published again.
  private func run() async -> RefreshResult {
    status = .loading
    await publishCache()

    let outcomes = await withTaskGroup(of: (Feed, RefreshOutcome).self) { [client, gate] group in
      for feed in feeds {
        group.addTask { await (feed, gate.pass(feed) { await client.fetch(feed) }) }
      }
      var outcomes: [Feed: RefreshOutcome] = [:]
      for await (feed, outcome) in group {
        outcomes[feed] = outcome
      }
      return outcomes
    }

    let now = client.now()
    var hasFailed = false
    for (feed, outcome) in outcomes {
      switch outcome {
        case .fetched(.updated),
             .fetched(.confirmed):
          failureTimes[feed] = nil

        case .fetched(.failed):
          failureTimes[feed] = now
          hasFailed = true

        case .gateClosed:
          break
      }
    }

    await publishCache()
    await client.updateSplatfestArt(for: snapshot.splatfest)
    status = hasFailed ? .failed : .loaded
    settledStatus = status
    return RefreshResult(outcomes: outcomes, snapshot: snapshot)
  }

  /// Rereads the cache and publishes it with this engine's stale marks.
  ///
  /// A feed whose refresh failed here stays stale across rereads until its record is renewed
  /// after the failure, by a 200 or a 304 from any engine. The marks live only in this engine, so
  /// a relaunched app starts from the cache with none.
  private func publishCache() async {
    var snapshot = await client.cache.snapshot()
    for (feed, failureTime) in failureTimes {
      if let fetchTime = snapshot.fetchTime(of: feed), fetchTime > failureTime {
        failureTimes[feed] = nil
      }
      else {
        snapshot.markStale(feed)
      }
    }
    self.snapshot = snapshot
  }
}

// MARK: - RefreshStatus

/// Where the engine's refresh stands.
public enum RefreshStatus: Hashable, Sendable {
  /// A refresh is in flight.
  case loading
  /// The last refresh ended with no feed failing.
  case loaded
  /// The last refresh ended with at least one feed failing.
  case failed
}
