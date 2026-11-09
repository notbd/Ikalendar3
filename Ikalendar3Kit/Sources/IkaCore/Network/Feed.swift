//
//  Feed.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Feed

/// One of splatoon3.ink's feeds the app reads. Each is requested, cached and decoded on its own,
/// so one feed failing leaves the others intact.
public enum Feed: Hashable, Sendable {
  /// `schedules.json`: every Schedule and the current Splatfest.
  case schedules
  /// `festivals.json`: every region's Splatfest records, for the current Splatfest's art and
  /// team names.
  case festivals
  /// `locale/<code>.json`: the game terms of one text set.
  case locale(GameLanguage)

  /// The feed's address on splatoon3.ink.
  public var url: URL {
    switch self {
      case .schedules: Source.feeds.appending(path: "schedules.json")
      case .festivals: Source.feeds.appending(path: "festivals.json")
      case .locale(let language): Source.feeds.appending(path: "locale/\(language.rawValue).json")
    }
  }

  /// The name the feed's cache record goes by.
  var recordName: String {
    switch self {
      case .schedules: "schedules"
      case .festivals: "festivals"
      case .locale(let language): "locale-\(language.rawValue)"
    }
  }

  /// Whether a body decodes as this feed, which makes it worth keeping.
  func accepts(_ body: Data) async -> Bool {
    switch self {
      case .schedules: await (try? ScheduleFeed.decode(from: body)) != nil
      case .festivals: await (try? FestivalFeed.decode(from: body)) != nil
      case .locale: await (try? TermTable.decode(from: body)) != nil
    }
  }
}

// MARK: - Source

/// The only hosts the app contacts, both over HTTPS: splatoon3.ink for feeds and its asset host
/// for images. The feed account's avatar on Nintendo's host is never loaded.
enum Source {
  /// The folder that holds the feeds. A fixed literal, so it always parses.
  static let feeds: URL = .init(string: "https://splatoon3.ink/data/")!
  /// splatoon3.ink and its asset host.
  static let hosts: Set<String> = ["splatoon3.ink", "assets.splatoon3.ink"]

  /// Whether an address is on one of the two hosts, over HTTPS.
  static func serves(_ url: URL) -> Bool {
    url.scheme == "https" && url.host().map(hosts.contains) == true
  }
}
