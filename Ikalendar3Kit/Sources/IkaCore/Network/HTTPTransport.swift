//
//  HTTPTransport.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - HTTPTransport

/// Sends one HTTP request and returns the answer. `URLSessionTransport` ships; tests and fixture
/// launches use `IkaFixtures`' scripted transport.
public protocol HTTPTransport: Sendable {
  /// Sends a request and returns the server's answer, whatever its status. Runs off the caller's
  /// actor and stops when its task is cancelled.
  ///
  /// - Throws: When no answer arrives: no network, a DNS failure, a timeout or cancellation.
  @concurrent
  func send(_ request: URLRequest) async throws -> HTTPResponse
}

// MARK: - HTTPResponse

/// A server's answer: status, headers and body.
public struct HTTPResponse: Hashable, Sendable {
  /// The HTTP status code.
  public let status: Int
  /// The header fields as the server sent them.
  public let headers: [String: String]
  /// The body, decompressed. Empty for a 304.
  public let body: Data

  /// An answer with the given parts.
  public init(status: Int, headers: [String: String] = [:], body: Data = Data()) {
    self.status = status
    self.headers = headers
    self.body = body
  }

  /// The value of a header field, its name matched case-insensitively as HTTP requires.
  public func value(forHTTPHeaderField name: String) -> String? {
    headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
  }
}
