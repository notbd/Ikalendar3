//
//  ScheduleFeed.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - ScheduleFeed

/// splatoon3.ink's `schedules.json`, decoded: every Schedule it publishes.
///
/// Each Schedule decodes on its own: a window that lacks one Battle Mode's setting fails only
/// that Battle Mode. A list that is missing, empty or malformed fails every Schedule it holds,
/// because they share its windows; so does a malformed setting, which names no Battle Mode. A
/// failed Schedule is empty and named in `failedSections`; every other Schedule stays intact.
public struct ScheduleFeed: Hashable, Sendable {
  let rotationsByMode: [RotationMode: [Rotation]]

  /// The published Challenges, in the order their first windows open.
  public let challenges: [Challenge]

  /// Salmon Run's Schedule: the regular Shifts and Big Runs, in time order.
  public let salmonRun: [Shift]

  /// The published Eggstra Works in time order. Each runs beside the regular Shifts.
  public let eggstraWork: [Shift]

  /// The announced or running Splatfest. `Snapshot.splatfest` completes it with
  /// `festivals.json`.
  let currentSplatfest: CurrentSplatfest?

  /// The English names the feed writes beside its ids. `Snapshot.feedTerms` adds the
  /// Splatfest's team names from `festivals.json`.
  let terms: TermTable

  /// The parts of the feed that failed to decode and are empty here.
  public let failedSections: Set<Section>

  /// The Rotations of a Battle Mode in time order. A continuous Battle Mode's include the
  /// paused ones while a Splatfest runs; Splatfest Battle's exist only while it runs.
  ///
  /// Internal so a paused Rotation never leaves IkaCore: Surfaces take a Battle Mode's Rotations
  /// from a lineup or a projection, which hold only Rotations that play.
  func rotations(for mode: RotationMode) -> [Rotation] {
    rotationsByMode[mode] ?? []
  }
}

// MARK: ScheduleFeed.Section

extension ScheduleFeed {
  /// A part of the feed that decodes on its own (GLOSSARY.md's Section).
  public enum Section: Hashable, Sendable {
    /// One Battle Mode's Rotations.
    case rotations(RotationMode)
    /// The Challenges.
    case challenges
    /// Salmon Run's regular Shifts and Big Runs, which fail together.
    case salmonRun
    /// The Eggstra Works.
    case eggstraWork
    /// The current Splatfest.
    case splatfest
  }
}

// MARK: ScheduleFeed.CurrentSplatfest

extension ScheduleFeed {
  /// The schedules feed's Splatfest with the Nintendo id its `festivals.json` record has.
  struct CurrentSplatfest: Hashable {
    /// Nintendo's id, which names the region (`Fest-US:JUEA-00108`, base64-encoded).
    let feedID: String
    let splatfest: Splatfest
  }
}
