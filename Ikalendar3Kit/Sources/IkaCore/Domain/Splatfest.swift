//
//  Splatfest.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Splatfest

/// A time-limited community event in which players pick one of three teams. Its title and team
/// names are terms, looked up by `id`; its Open and Pro Rotations are Splatfest Battle's
/// Rotations in the schedules feed.
public struct Splatfest: Hashable, Sendable {
  /// The Splatfest's code, which also keys its texts.
  public let id: SplatfestID
  /// When the Splatfest starts.
  public let startTime: Date
  /// When its second half, with Tricolor Turf War, starts.
  public let midtermTime: Date
  /// When the Splatfest ends.
  public let endTime: Date
  /// The three teams' colours from the feed, in the feed's order (Alpha, Bravo, Charlie), which
  /// is also the order of the team names in the terms.
  public let teamColors: [RGBAColor]
  /// The Stages of Tricolor Turf War, which runs in the second half.
  public let tricolorStages: [StageID]
  /// The Splatfest's art on splatoon3.ink's asset host, when `festivals.json` has its record.
  internal(set) public var artURL: URL?
}

// MARK: - RGBAColor

/// A colour as the feed gives it: red, green, blue and opacity, each from 0 to 1.
public struct RGBAColor: Hashable, Sendable {
  /// The red component.
  public let red: Double
  /// The green component.
  public let green: Double
  /// The blue component.
  public let blue: Double
  /// The opacity.
  public let alpha: Double
}
