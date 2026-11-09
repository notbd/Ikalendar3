//
//  FeedClient.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

// MARK: - FeedClient

/// The one request path to splatoon3.ink. It sends each feed's request politely (naming the app
/// and revalidating with the stored ETag) and commits each good answer to the cache.
public struct FeedClient: Sendable {
  /// Where good answers go.
  public let cache: FeedCache

  private let transport: any HTTPTransport
  private let userAgent: String
  private let timeout: Duration
  private let now: @Sendable () -> Date

  /// A client that sends through a transport and keeps good answers in a cache.
  ///
  /// - Parameters:
  ///   - appVersion: The marketing version named in the `User-Agent`: by default the running
  ///     bundle's, which an app extension shares with its app.
  ///   - timeout: How long a request may take before it counts as unanswered, whatever the
  ///     transport does.
  ///   - now: The wall clock that stamps fetch times.
  public init(
    transport: any HTTPTransport,
    cache: FeedCache,
    appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0",
    timeout: Duration = resourceTimeout,
    now: @escaping @Sendable () -> Date = { Date() })
  {
    self.transport = transport
    self.cache = cache
    userAgent = Self.userAgent(appVersion: appVersion)
    self.timeout = timeout
    self.now = now
  }

  /// Requests a feed and commits a good answer to the cache. Runs off the main actor.
  ///
  /// Callers send one request per feed at a time across processes (the refresh engine's attempt
  /// lock sees to it), so the record a 304 confirms is still the one stored.
  @concurrent
  public func fetch(_ feed: Feed) async -> FetchOutcome {
    let stored = await validRecord(for: feed)

    let response: HTTPResponse
    do {
      // The ETag goes back only while a valid body is stored, so a lost body never earns an
      // endless 304.
      response = try await send(to: feed.url, ifNoneMatch: stored?.etag)
    }
    catch {
      Logger.network.error("\(feed.url, privacy: .public): no answer: \(error, privacy: .public)")
      return .failed(.noAnswer)
    }

    switch (response.status, stored) {
      case (200, _):
        guard await feed.accepts(response.body) else {
          Logger.network.error("\(feed.url, privacy: .public): the 200's body does not decode")
          return .failed(.undecodable)
        }

        let record: FeedRecord = .init(
          body: response.body,
          etag: response.value(forHTTPHeaderField: "ETag"),
          fetchTime: now())
        return commit(record, for: feed, as: .updated)

      case (304, let stored?):
        let record: FeedRecord = .init(body: stored.body, etag: stored.etag, fetchTime: now())
        return commit(record, for: feed, as: .confirmed)

      default:
        Logger.network.error("\(feed.url, privacy: .public): status \(response.status)")
        return .failed(.status(response.status))
    }
  }

  /// Keeps the cache's Splatfest art in step with the current Splatfest. The art of a Splatfest
  /// that is not over yet is downloaded once, when none is stored; the art of every other
  /// Splatfest, and of one that is over, is removed. A failed download leaves no art, so views
  /// fall back to the team colours, and the next call tries again. Runs off the main actor.
  ///
  /// - Parameter splatfest: The Splatfest the feed names, or `nil` when it names none.
  @concurrent
  public func updateSplatfestArt(for splatfest: Splatfest?) async {
    let current = splatfest.flatMap { now() < $0.endTime ? $0 : nil }
    cache.removeSplatfestArt(keeping: current?.id)
    guard let current, let url = current.artURL, cache.splatfestArt(for: current.id) == nil else { return }

    do {
      let response = try await send(to: url)
      guard response.status == 200, !response.body.isEmpty else {
        Logger.network.error("\(url, privacy: .public): status \(response.status), \(response.body.count) bytes")
        return
      }

      try cache.commitSplatfestArt(response.body, for: current.id)
    }
    catch {
      Logger.network.error("\(url, privacy: .public): no art: \(error, privacy: .public)")
    }
  }

  /// The feed's stored record when its body still decodes, which is what a 304 can confirm.
  private func validRecord(for feed: Feed) async -> FeedRecord? {
    guard let record = cache.record(for: feed), await feed.accepts(record.body) else { return nil }

    return record
  }

  /// Commits a record and reports the outcome, or the failure to store it.
  private func commit(_ record: FeedRecord, for feed: Feed, as outcome: FetchOutcome) -> FetchOutcome {
    do {
      try cache.commit(record, for: feed)
      return outcome
    }
    catch {
      Logger.store.error("\(feed.url, privacy: .public): not stored: \(error, privacy: .public)")
      return .failed(.notStored)
    }
  }

  /// Sends a GET that names the app, revalidating with an ETag sent back exactly as received.
  ///
  /// - Throws: `URLError(.unsupportedURL)` for an address off splatoon3.ink's two hosts, which is
  ///   never requested, or when no answer arrives within the timeout.
  private func send(to url: URL, ifNoneMatch etag: String? = nil) async throws -> HTTPResponse {
    guard Source.serves(url) else { throw URLError(.unsupportedURL) }

    let request = {
      var request: URLRequest = .init(url: url)
      request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
      request.setValue(etag, forHTTPHeaderField: "If-None-Match")
      return request
    }()

    return try await withThrowingTaskGroup { group in
      group.addTask { try await transport.send(request) }
      group.addTask {
        try await Task.sleep(for: timeout)
        throw URLError(.timedOut)
      }
      defer { group.cancelAll() }

      guard let response = try await group.next() else { throw URLError(.timedOut) }

      return response
    }
  }

  /// `ikalendar3/<version> (+https://ikalendar.app/3; ikalendar3@tianwei.io)`: the app, its
  /// version and how to reach its developer, as splatoon3.ink asks of every client.
  static func userAgent(appVersion: String) -> String {
    "ikalendar3/\(appVersion) (+https://ikalendar.app/3; ikalendar3@tianwei.io)"
  }
}

extension FeedClient {
  /// How long one request may take in all before it counts as unanswered: ikalendar 2's resource
  /// timeout, which `URLSessionTransport` also sets.
  static public let resourceTimeout: Duration = .seconds(30)
}

// MARK: - FetchOutcome

/// What one feed request did to the cache.
public enum FetchOutcome: Hashable, Sendable {
  /// A 200 whose body decodes: its body, ETag and fetch time replaced the record together.
  case updated
  /// A 304: the stored body stands, and its fetch time is renewed.
  case confirmed
  /// Anything else. The stored record is untouched.
  case failed(FetchFailure)
}

// MARK: - FetchFailure

/// Why a feed request kept the stored record.
public enum FetchFailure: Error, Hashable, Sendable {
  /// No answer arrived: no network, a DNS failure or a timeout.
  case noAnswer
  /// An answer the client cannot use: any status but 200, or a 304 with no valid body stored.
  case status(Int)
  /// A 200 whose body does not decode as the feed.
  case undecodable
  /// A good answer the cache could not write.
  case notStored
}
