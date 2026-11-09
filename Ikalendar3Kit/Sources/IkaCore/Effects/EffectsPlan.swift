//
//  EffectsPlan.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - EffectsPlan

/// The effects one run of the effects shell applies after its refresh. Every decision is made
/// here, where it is tested; the shell in `IkaIntents` applies the plan and decides nothing itself.
public struct EffectsPlan: Hashable, Sendable {
  /// Whether every widget timeline reloads: after each refresh that committed a feed, a 304
  /// included, so the widgets show the fetch time the app shows.
  public let reloadsWidgetTimelines: Bool

  /// The plan after a refresh.
  public init(after result: RefreshResult) {
    reloadsWidgetTimelines = result.hasCommitted
  }
}

// MARK: - RefreshResult

extension RefreshResult {
  /// Whether the refresh committed any feed's answer: a new body, or a 304's renewed fetch time.
  /// A refresh whose every feed failed or was kept from the network by the gate left the cache as
  /// it was.
  fileprivate var hasCommitted: Bool {
    outcomes.values.contains { outcome in
      switch outcome {
        case .fetched(.updated),
             .fetched(.confirmed): true
        case .fetched(.failed),
             .gateClosed: false
      }
    }
  }
}
