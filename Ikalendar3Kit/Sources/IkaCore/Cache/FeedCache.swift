//
//  FeedCache.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

// MARK: - FeedCache

/// The last good response of each feed, kept in a directory every process on the device reads:
/// the App Group container on iPhone, iPad and Mac, the watch's own container on the watch.
///
/// Each feed's record is one file, replaced whole by an atomic rename. Other processes read it at
/// any moment, so a reader sees the previous record or the new one, never a mix, and a write
/// interrupted by a killed process leaves the previous record in place.
public struct FeedCache: Sendable {
  /// The directory that holds the records.
  public let directory: URL

  /// A cache in a directory, which it creates on the first write if needed.
  public init(directory: URL) {
    self.directory = directory
  }

  /// A feed's stored record, or `nil` when there is none or it cannot be read.
  public func record(for feed: Feed) -> FeedRecord? {
    guard let data = try? Data(contentsOf: recordURL(for: feed)) else { return nil }

    return try? PropertyListDecoder().decode(FeedRecord.self, from: data)
  }

  /// Replaces a feed's record in one atomic step.
  public func commit(_ record: FeedRecord, for feed: Feed) throws {
    let encoder: PropertyListEncoder = .init()
    encoder.outputFormat = .binary
    let data = try encoder.encode(record)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try data.write(to: recordURL(for: feed), options: .atomic)
  }

  /// Every stored feed, decoded, with its fetch time: how widgets and other read-only processes
  /// see the data. No feed is stale, because a cache records no failures. A feed with no record,
  /// or one that no longer decodes, is left out. Runs off the main actor.
  @concurrent
  public func snapshot() async -> Snapshot {
    var locales: [GameLanguage: Fetched<TermTable>] = [:]
    for language in GameLanguage.allCases {
      locales[language] = await fetched(.locale(language), decode: TermTable.decode)
    }
    return await Snapshot(
      schedules: fetched(.schedules, decode: ScheduleFeed.decode),
      festivals: fetched(.festivals, decode: FestivalFeed.decode),
      locales: locales)
  }

  /// A feed's stored content with its fetch time, or `nil` when it has no record that decodes.
  private func fetched<Content>(
    _ feed: Feed,
    decode: (Data) async throws -> Content)
    async -> Fetched<Content>?
  {
    guard
      let record = record(for: feed),
      let content = try? await decode(record.body)
    else { return nil }

    return Fetched(content: content, fetchTime: record.fetchTime)
  }

  private func recordURL(for feed: Feed) -> URL {
    directory.appending(path: "\(feed.recordName).plist")
  }

  // MARK: Splatfest art

  /// A Splatfest's stored art as a local image file, or `nil` when none is stored.
  public func splatfestArt(for id: SplatfestID) -> URL? {
    let url = artURL(for: id)
    return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
  }

  /// Stores a Splatfest's art in one atomic step, so a reader never sees part of an image.
  func commitSplatfestArt(_ art: Data, for id: SplatfestID) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try art.write(to: artURL(for: id), options: .atomic)
  }

  /// Removes every Splatfest's stored art but one's.
  func removeSplatfestArt(keeping id: SplatfestID?) {
    let kept = id.map(artURL)?.lastPathComponent
    let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))) ?? []
    for name in names where name.hasPrefix(Self.artPrefix) && name.hasSuffix(Self.artSuffix) && name != kept {
      do {
        try FileManager.default.removeItem(at: directory.appending(path: name))
      }
      catch {
        Logger.store.error("\(name, privacy: .public): not removed: \(error, privacy: .public)")
      }
    }
  }

  static private let artPrefix = "splatfest-"
  static private let artSuffix = ".png"

  /// The art's file, named by the Splatfest's code (the asset host serves the art as PNG). The
  /// code comes from the network, so anything but letters, digits and hyphens is percent-encoded
  /// and cannot reach another folder.
  private func artURL(for id: SplatfestID) -> URL {
    let code = id.rawValue.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(["-"])) ?? ""
    return directory.appending(path: Self.artPrefix + code + Self.artSuffix)
  }
}
