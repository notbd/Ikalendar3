//
//  FeedGate.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

// MARK: - FeedGate

/// The one network gate every engine on a directory shares, so the source sees at most one
/// answered request per feed an hour, as splatoon3.ink asks. The Splatfest art's download passes
/// it under a key of its own, so a failing download backs off like a feed.
///
/// - A feed is requested only once its last answered request is an hour old. Any HTTP status
///   is an answer, an undecodable 200 included.
/// - A request with no answer backs off instead: 30 s, doubling up to an hour. Any answer resets
///   the back-off.
/// - Each feed's attempt record lives in the directory, apart from the cache, and is checked and
///   written under one file lock before the request goes out. Claiming an attempt is therefore
///   atomic across processes and within one.
/// - A claim holds the feed for the lease, a little longer than the client's timeout, while its
///   request is in flight and its answer is committed; its outcome then sets the next eligible
///   time. A claim whose process was killed mid-request
///   frees the feed once its lease passes.
struct FeedGate {
  /// The directory the attempt records share with the cache.
  let directory: URL
  /// How long a claim holds the feed while its request is in flight and its answer is committed.
  let lease: Duration
  /// The wall clock.
  let now: @Sendable () -> Date

  /// Sends a feed's request through `send` when the gate is open and records its outcome.
  ///
  /// While another engine's request for the feed is in flight, waits for it: rereads the attempt
  /// record at a short interval until that request's outcome is written, then reports the gate
  /// closed; if the lease passes with no outcome, claims the attempt itself. Runs off the main
  /// actor.
  @concurrent
  func pass(_ key: Key, send: @Sendable () async -> FetchOutcome) async -> RefreshOutcome {
    while true {
      switch claim(key) {
        case .claimed(let claim):
          let outcome = await send()
          settle(claim, isAnswered: outcome != .failed(.noAnswer))
          return .fetched(outcome)

        case .leased:
          do {
            try await Task.sleep(for: Self.leasePollInterval)
          }
          catch {
            return .gateClosed
          }

        case .closed:
          return .gateClosed
      }
    }
  }

  /// How often an engine waiting on another's lease rereads the attempt record.
  static private let leasePollInterval: Duration = .milliseconds(100)

  // MARK: Attempt records

  /// Claims the next attempt at a feed if its gate is open. A gate whose records cannot be read
  /// and written stays closed, so no request goes out unrecorded.
  func claim(_ key: Key) -> Claim {
    let now = now()
    let name = key.recordName
    return withRecords { records in
      // An attempt well after `now` means the clock was set back: its wait no longer measures
      // time. A small step back, as a time sync makes, keeps the gate as it was.
      if
        let record = records[name], now < record.nextEligibleTime,
        record.attemptTime <= now.addingTimeInterval(Self.clockStepTolerance / .seconds(1))
      {
        guard record.lease == nil else { return .leased }

        Logger.network.debug("\(name, privacy: .public): gate closed until \(record.nextEligibleTime)")
        return .closed
      }

      let claim: Claim.Granted = .init(key: name)
      records[name] = AttemptRecord(
        attemptTime: now,
        nextEligibleTime: now.addingTimeInterval(lease / .seconds(1)),
        backOff: records[name]?.backOff,
        lease: claim.id)
      return .claimed(claim)
    } ?? .closed
  }

  /// How far the clock may step back after an attempt before the attempt's wait stops counting.
  static let clockStepTolerance: Duration = .seconds(60)

  /// Writes a claimed request's outcome: the next attempt an hour after an answer, or after the
  /// next back-off step when no answer came.
  func settle(_ claim: Claim.Granted, isAnswered: Bool) {
    let now = now()
    withRecords { records in
      guard var record = records[claim.key], record.lease == claim.id else { return }

      record.backOff = isAnswered ? nil : record.backOff.map { min($0 * 2, Self.interval) } ?? Self.firstBackOff
      record.nextEligibleTime = now.addingTimeInterval((record.backOff ?? Self.interval) / .seconds(1))
      record.lease = nil
      records[claim.key] = record
    }
  }

  /// How long an answer closes the gate, and the longest back-off.
  static let interval: Duration = .seconds(60 * 60)
  /// The wait after the first unanswered request.
  static let firstBackOff: Duration = .seconds(30)

  // MARK: File lock

  private var recordsURL: URL { directory.appending(path: "attempts.plist") }
  private var lockURL: URL { directory.appending(path: "attempts.lock") }

  /// Reads the attempt records, lets `body` change them and writes them back, all under the
  /// exclusive lock of `attempts.lock`. Returns `nil`, logged, when the lock or the write fails.
  ///
  /// The lock is `flock`'s, taken by `open` with `O_EXLOCK`: it belongs to the open file, so two
  /// engines in one process exclude each other as two processes do, which a POSIX record lock
  /// (`fcntl`, `lockf`) would not. The records live in a file of their own, replaced by an atomic
  /// rename, so the locked file is never replaced. The lock is held for one read and one write,
  /// never across a suspension.
  @discardableResult
  private func withRecords<Result>(_ body: (inout [String: AttemptRecord]) -> Result) -> Result? {
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let descriptor = open(lockURL.path(percentEncoded: false), O_RDWR | O_CREAT | O_EXLOCK | O_CLOEXEC, 0o644)
      guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }

      defer { close(descriptor) }

      let data = try? Data(contentsOf: recordsURL)
      var records = data.flatMap { try? PropertyListDecoder().decode([String: AttemptRecord].self, from: $0) } ?? [:]
      let before = records
      let result = body(&records)
      if records != before {
        let encoder: PropertyListEncoder = .init()
        encoder.outputFormat = .binary
        try encoder.encode(records).write(to: recordsURL, options: .atomic)
      }
      return result
    }
    catch {
      Logger.store.error("attempt records: \(error, privacy: .public)")
      return nil
    }
  }
}

// MARK: FeedGate.Key

extension FeedGate {
  /// What one attempt record gates.
  enum Key: Hashable, Sendable {
    /// A feed's requests.
    case feed(Feed)
    /// The current Splatfest art's download.
    case splatfestArt

    /// The name the attempt record goes by.
    var recordName: String {
      switch self {
        case .feed(let feed): feed.recordName
        case .splatfestArt: "splatfest-art"
      }
    }
  }
}

// MARK: FeedGate.Claim

extension FeedGate {
  /// The gate's answer to a claim.
  enum Claim {
    /// The gate was open: the caller holds the attempt and sends the request.
    case claimed(Granted)
    /// Another claim's request is in flight and its lease has not passed.
    case leased
    /// The gate is closed: no request goes out.
    case closed

    /// A claimed attempt, which only its own outcome may settle.
    struct Granted {
      /// The feed's record name.
      let key: String
      /// The lease written with the claim.
      let id: UUID = .init()
    }
  }
}

// MARK: - AttemptRecord

/// A feed's last attempt, kept apart from its fetch time.
struct AttemptRecord: Codable, Hashable {
  /// When the last request was claimed.
  var attemptTime: Date
  /// When the feed may be requested again.
  var nextEligibleTime: Date
  /// The wait the last unanswered request set, which the next one doubles; `nil` once a request
  /// is answered.
  var backOff: Duration?
  /// The claim whose request is in flight, or `nil` once its outcome is written.
  var lease: UUID?
}
