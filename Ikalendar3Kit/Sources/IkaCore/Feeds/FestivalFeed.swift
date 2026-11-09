//
//  FestivalFeed.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

// MARK: - FestivalFeed

/// splatoon3.ink's `festivals.json`, decoded: every region's Splatfest records, which complete
/// the schedules feed's current Splatfest with its art and team names.
public struct FestivalFeed: Hashable, Sendable {
  /// Each region's records by Nintendo's Splatfest id, which names the region
  /// (`Fest-US:JUEA-00108`, base64-encoded as the feed writes it).
  let records: [String: Record]
}

extension FestivalFeed {
  /// One region's record of a Splatfest.
  struct Record: Hashable {
    let id: SplatfestID
    /// The title in the region's language, which is English for the US account.
    let title: String
    /// The team names in the feed's order, in the same language as the title.
    let teamNames: [String]
    let artURL: URL?
  }

  /// Decodes a `festivals.json` response body. Runs off the main actor. A region or a record
  /// that fails on its own is left out.
  ///
  /// - Throws: `DecodingError` when the body is not the festivals feed: no region decodes.
  @concurrent
  static public func decode(from body: Data) async throws -> FestivalFeed {
    let parts = try FeedJSON.decoder().decode([String: Isolated<RegionDTO>].self, from: body)
    let regions = parts.compactMap { name, part in
      do {
        return try part.result.get()
      }
      catch {
        Logger.decode.error("festivals: region \(name, privacy: .public) failed: \(error, privacy: .public)")
        return nil
      }
    }
    if regions.isEmpty, case .failure(let error)? = parts.values.first?.result {
      throw error
    }

    let records = regions
      .flatMap(\.data.festRecords.nodes)
      .compactMap { try? $0.result.get() }
      .map { record in
        (
          record.id,
          Record(
            id: SplatfestID(record.code),
            title: record.title,
            teamNames: record.teams.map(\.teamName),
            artURL: record.image.flatMap { URL(string: $0.url) }))
      }
    return FestivalFeed(records: .init(records, uniquingKeysWith: { first, _ in first }))
  }
}

// MARK: - RegionDTO

/// One region's list, newest Splatfest first.
private struct RegionDTO: Decodable {
  struct DataDTO: Decodable {
    let festRecords: NodesDTO
  }

  struct NodesDTO: Decodable {
    let nodes: [Isolated<RecordDTO>]
  }

  let data: DataDTO
}

// MARK: - RecordDTO

private struct RecordDTO: Decodable {
  struct TeamDTO: Decodable {
    let teamName: String
  }

  struct ImageDTO: Decodable {
    let url: String
  }

  /// Nintendo's id, which names the region.
  let id: String
  /// splatoon3.ink's Splatfest code, the same in every region.
  let code: String
  let title: String
  let teams: [TeamDTO]
  let image: ImageDTO?

  enum CodingKeys: String, CodingKey {
    case id
    case code = "__splatoon3ink_id"
    case title
    case teams
    case image
  }
}
