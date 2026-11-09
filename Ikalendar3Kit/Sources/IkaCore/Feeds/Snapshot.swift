//
//  Snapshot.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Snapshot

/// The decoded data of every feed, each with its fetch time and whether it is stale. The cache
/// reads it back and the engine publishes it; every Surface's content is a pure function of it.
public struct Snapshot: Equatable, Sendable {
  /// `schedules.json`, or `nil` before its first good response.
  public var schedules: Fetched<ScheduleFeed>?
  /// `festivals.json`, or `nil` before its first good response.
  public var festivals: Fetched<FestivalFeed>?
  /// The locale files fetched so far, by the text set each holds.
  public var locales: [GameLanguage: Fetched<TermTable>]
  /// The stored art of the current Splatfest, a local image file, or `nil` while none is stored:
  /// views then show the team colours.
  public var splatfestArt: URL?

  /// A snapshot of the given feeds. Leave a feed out when it has no good response yet.
  public init(
    schedules: Fetched<ScheduleFeed>? = nil,
    festivals: Fetched<FestivalFeed>? = nil,
    locales: [GameLanguage: Fetched<TermTable>] = [:],
    splatfestArt: URL? = nil)
  {
    self.schedules = schedules
    self.festivals = festivals
    self.locales = locales
    self.splatfestArt = splatfestArt
  }
}

extension Snapshot {
  /// The current Splatfest: the schedules feed's, completed with the art address of its record in
  /// `festivals.json`. `nil` while the schedules feed names none. `splatfestArt` is its stored
  /// art.
  ///
  /// Region: the schedules feed's Splatfest is the one splatoon3.ink's US account sees. Every
  /// Splatfest since 2024-04-20 was shared by all four regions, so it is taken as shown, with no
  /// region setting. Its record is found by the same Nintendo id, which names that region.
  public var splatfest: Splatfest? {
    guard let current = schedules?.content.currentSplatfest else { return nil }

    var splatfest = current.splatfest
    splatfest.artURL = festivals?.content.records[current.feedID]?.artURL
    return splatfest
  }

  /// The feeds' own English names: the last fallback of every term lookup, after the locale
  /// tables. The current Splatfest's title and team names come from its `festivals.json`
  /// record when there is one, else its title from the schedules feed, with no team names.
  public var feedTerms: TermTable {
    var terms = schedules?.content.terms ?? TermTable()
    if
      let current = schedules?.content.currentSplatfest,
      let record = festivals?.content.records[current.feedID]
    {
      terms.splatfests[record.id] = SplatfestTerms(title: record.title, teamNames: record.teamNames)
    }
    return terms
  }
}

// MARK: - Fetched

/// A feed's decoded content with its freshness.
public struct Fetched<Content: Sendable>: Sendable {
  /// The decoded content of the last good response.
  public var content: Content
  /// The last time the source confirmed the content, by a 200 or a 304.
  public var fetchTime: Date
  /// Whether the last refresh of this feed failed. Only the engine run that saw the failure
  /// sets it: content read from the cache is never stale, and system Surfaces judge freshness
  /// by the fetch time's age instead.
  public var isStale: Bool

  /// Content with its fetch time, not stale unless a refresh just failed.
  public init(content: Content, fetchTime: Date, isStale: Bool = false) {
    self.content = content
    self.fetchTime = fetchTime
    self.isStale = isStale
  }
}

// MARK: Equatable

extension Fetched: Equatable where Content: Equatable { }

// MARK: Hashable

extension Fetched: Hashable where Content: Hashable { }
