//
//  FeedDecoding.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - FeedJSON

/// The JSON decoding every splatoon3.ink feed shares.
enum FeedJSON {
  /// A decoder for the feeds' ISO 8601 UTC times (`2026-10-20T12:00:00Z`).
  static func decoder() -> JSONDecoder {
    let decoder: JSONDecoder = .init()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}

// MARK: - Isolated

/// A value decoded on its own: its failure is kept instead of failing the value that holds it.
/// Declare it optional, so a missing key or a `null` decodes as `nil` too.
struct Isolated<Value: Decodable>: Decodable {
  let result: Result<Value, any Error>

  init(from decoder: any Decoder) {
    result = Result { try Value(from: decoder) }
  }
}

// MARK: - FeedDecodingError

/// Why a part of a feed that is valid JSON still cannot be used.
enum FeedDecodingError: Error {
  /// The part is missing or `null`.
  case missing
  /// The list holds no items.
  case emptyList
  /// A window lists settings, but none for this Battle Mode.
  case missingSetting(RotationMode)
  /// A Splatfest id holds no Splatfest code.
  case malformedSplatfestID(String)
}
