//
//  FeedID.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - FeedID

/// An id from splatoon3.ink's feeds, tagged with the kind of item it names, so a Stage id can
/// never stand in for a Rule id. Every item is keyed by its feed id, never by its English name,
/// so a renamed or translated item keeps its identity. Two ids are equal only when their strings
/// are: base64 ids are case-sensitive.
public struct FeedID<Kind>: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible {
  /// The id as the feed writes it.
  public let rawValue: String

  /// Wraps an id as the feed writes it.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  /// Wraps an id as the feed writes it.
  public init(_ rawValue: String) {
    self.init(rawValue: rawValue)
  }

  /// The id as the feed writes it.
  public var description: String { rawValue }
}

// MARK: - FeedIDKind

/// The kinds of item a `FeedID` names. They only tag ids and have no values.
public enum FeedIDKind {
  /// Tags `StageID`.
  public enum Stage { }
  /// Tags `RuleID`.
  public enum Rule { }
  /// Tags `WeaponID`.
  public enum Weapon { }
  /// Tags `KingSalmonidID`.
  public enum KingSalmonid { }
  /// Tags `ChallengeID`.
  public enum Challenge { }
  /// Tags `SplatfestID`.
  public enum Splatfest { }
}

/// A Stage, battle or Salmon Run, by Nintendo's base64 id (`VsStage-1`, `CoopStage-8`).
public typealias StageID = FeedID<FeedIDKind.Stage>

/// A Rule by Nintendo's base64 id (`VsRule-0` is Turf War).
public typealias RuleID = FeedID<FeedIDKind.Rule>

/// A Salmon Run weapon by splatoon3.ink's derived id: Nintendo gives weapons no id, so
/// splatoon3.ink hashes the image path into 16 hex digits. It changes if Nintendo re-uploads
/// the art.
public typealias WeaponID = FeedID<FeedIDKind.Weapon>

/// A King Salmonid by Nintendo's base64 id (`CoopEnemy-23` is Cohozuna).
public typealias KingSalmonidID = FeedID<FeedIDKind.KingSalmonid>

/// A Challenge by Nintendo's base64 id (`LeagueMatchEvent-…`).
public typealias ChallengeID = FeedID<FeedIDKind.Challenge>

/// A Splatfest by splatoon3.ink's Splatfest code (`JUEA-00108`): the id `festivals.json` and the
/// locale files key Splatfests by. Nintendo's own id adds the region of the account that saw it
/// (`Fest-US:JUEA-00108`); the code is the same in every region that holds the Splatfest.
public typealias SplatfestID = FeedID<FeedIDKind.Splatfest>
