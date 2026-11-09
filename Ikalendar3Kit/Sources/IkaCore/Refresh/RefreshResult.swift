//
//  RefreshResult.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - RefreshResult

/// What one refresh did: each feed's outcome and the snapshot it published. The effects plan is
/// built from it.
public struct RefreshResult: Equatable, Sendable {
  /// Each refreshed feed's outcome.
  public let outcomes: [Feed: RefreshOutcome]
  /// The snapshot the refresh published: the cache as the refresh left it.
  public let snapshot: Snapshot
}

// MARK: - RefreshOutcome

/// What a refresh did with one feed.
public enum RefreshOutcome: Hashable, Sendable {
  /// The engine requested the feed, with this outcome.
  case fetched(FetchOutcome)
  /// The engine sent no request: the feed's last answered request is under an hour old, its
  /// back-off is still running, another engine's request just settled it, or its attempt record
  /// could not be read and written. The cached data is re-projected without a download.
  case gateClosed
}
