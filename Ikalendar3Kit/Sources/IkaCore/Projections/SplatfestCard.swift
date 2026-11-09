//
//  SplatfestCard.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - SplatfestCard

/// A Splatfest with its stored art: what every Splatfest card shows, on the Splatfest screen, on
/// Regular Battle's screen while it is announced and among the events. The one value that carries
/// the two together, so no card is handed them apart.
public struct SplatfestCard: Hashable, Sendable {
  /// The Splatfest: its times, team colours and id, which keys its title and team names.
  public let splatfest: Splatfest
  /// Its art, a local image file the refresh engine stored, or `nil` while none is downloaded:
  /// the card shows the team colours alone then.
  public let art: URL?
}

extension Snapshot {
  /// `splatfest`'s card with the art stored for the current Splatfest.
  func card(of splatfest: Splatfest) -> SplatfestCard {
    SplatfestCard(splatfest: splatfest, art: splatfestArt)
  }
}
