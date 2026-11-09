//
//  Challenge.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Challenge

/// A limited-time Battle Mode event with its own rules, held in several fixed windows on one
/// day. Its name, description and rules text are terms, looked up by `id`.
public struct Challenge: Hashable, Sendable {
  /// The Challenge's id, which also keys its texts.
  public let id: ChallengeID
  /// The Rule played in every window.
  public let rule: RuleID
  /// The Stages played in every window, in the feed's order.
  public let stages: [StageID]
  /// The windows the Challenge is held in, in time order: usually six two-hour windows four
  /// hours apart.
  public let windows: [Window]
}

// MARK: Challenge.Window

extension Challenge {
  /// One window a Challenge is held in.
  public struct Window: Hashable, Sendable {
    /// When the window opens.
    public let startTime: Date
    /// When the window closes.
    public let endTime: Date
  }
}
