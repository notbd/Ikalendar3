//
//  Rotation.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Rotation

/// A fixed window during which one Battle Mode runs one Rule on its Stages.
///
/// While a Splatfest runs, the feed still lists the continuous Battle Modes' windows but gives
/// them no Rule or Stages: those Rotations are paused, with a `nil` setting.
public struct Rotation: Hashable, Sendable {
  /// The Battle Mode the Rotation belongs to.
  public let mode: RotationMode
  /// When the Rotation starts.
  public let startTime: Date
  /// When the Rotation ends, which is when the next one starts.
  public let endTime: Date
  /// The Rule and Stages played, or `nil` while a Splatfest pauses the Battle Mode.
  public let setting: Setting?

  /// Whether a Splatfest pauses the Battle Mode during this Rotation.
  public var isPaused: Bool { setting == nil }
}

// MARK: Rotation.Setting

extension Rotation {
  /// What a Rotation plays.
  public struct Setting: Hashable, Sendable {
    /// The Rule.
    public let rule: RuleID
    /// The two Stages, in the feed's order.
    public let stages: [StageID]
  }
}

// MARK: - RotationMode

/// The Battle Mode a Rotation belongs to: one of the four continuous Battle Modes, or a form of
/// Splatfest Battle, which replaces them while a Splatfest runs.
public enum RotationMode: Hashable, Sendable {
  /// A continuous Battle Mode.
  case battle(BattleMode)
  /// Splatfest Battle in its Open or Pro form.
  case splatfestBattle(SplatfestBattleForm)
}

// MARK: - SplatfestBattleForm

/// The two forms of Splatfest Battle.
public enum SplatfestBattleForm: CaseIterable, Hashable, Sendable {
  /// Splatfest Battle (Open).
  case open
  /// Splatfest Battle (Pro).
  case pro
}
