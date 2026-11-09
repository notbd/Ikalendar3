//
//  FeedRecord.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - FeedRecord

/// A feed's last good response as the cache keeps it: body, ETag and fetch time, always from the
/// same response and always stored together.
public struct FeedRecord: Codable, Hashable, Sendable {
  /// The response body as received.
  public let body: Data
  /// The response's ETag as received, weak or strong, or `nil` when it had none.
  public let etag: String?
  /// The last time the source confirmed the body, by a 200 or a 304.
  public let fetchTime: Date

  /// A record of one response.
  public init(body: Data, etag: String?, fetchTime: Date) {
    self.body = body
    self.etag = etag
    self.fetchTime = fetchTime
  }
}
