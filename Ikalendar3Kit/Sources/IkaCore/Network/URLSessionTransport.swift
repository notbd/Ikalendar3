//
//  URLSessionTransport.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

// MARK: - URLSessionTransport

/// The shipping transport: a `URLSession` of its own with ikalendar 2's timeouts. It keeps no
/// HTTP cache, so every 304 reaches the feed client, which keeps the only cache; and it keeps no
/// cookies or credentials, so no request carries an identifier. It follows a redirect only to an
/// address on the two hosts over HTTPS (`RedirectGuard`), so no answer can take a request
/// anywhere else.
public struct URLSessionTransport: HTTPTransport {
  private let session: URLSession

  /// A transport with its own session.
  public init() {
    self.init(configuration: .ephemeral)
  }

  /// - Parameter configuration: Injectable so tests can stub answers through a `URLProtocol`;
  ///   the settings below apply to a copy, so the caller's object stays unchanged.
  init(configuration: URLSessionConfiguration) {
    let configuration = configuration.copy() as? URLSessionConfiguration ?? configuration
    // A hanging server fails the request within seconds, not URLSession's 60 s default.
    configuration.timeoutIntervalForRequest = 10
    configuration.timeoutIntervalForResource = TimeInterval(FeedClient.resourceTimeout.components.seconds)
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.urlCache = nil
    configuration.httpShouldSetCookies = false
    configuration.httpCookieStorage = nil
    configuration.urlCredentialStorage = nil
    session = URLSession(configuration: configuration, delegate: RedirectGuard(), delegateQueue: nil)
  }

  @concurrent
  public func send(_ request: URLRequest) async throws -> HTTPResponse {
    let (body, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

    var headers: [String: String] = [:]
    for case (let name as String, let value as String) in response.allHeaderFields {
      headers[name] = value
    }
    return HTTPResponse(status: response.statusCode, headers: headers, body: body)
  }
}

// MARK: - RedirectGuard

/// Follows a redirect only to an address `Source.serves`, hop by hop. A refused redirect is the
/// answer: its target never receives a request, and the feed client counts the 3xx as a failed
/// answer.
///
/// The completion handler's form, not the `async` one: Swift 6.4's compiler crashes emitting the
/// Objective-C thunk of the `async` form in this module.
final private class RedirectGuard: NSObject, URLSessionTaskDelegate, Sendable {
  func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    willPerformHTTPRedirection _: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping @Sendable (URLRequest?) -> Void)
  {
    guard let target = request.url, Source.serves(target) else {
      // The feed client logs the 3xx with the address it asked for.
      Logger.network.error("Redirect refused: \(request.url?.absoluteString ?? "no address", privacy: .public)")
      completionHandler(nil)
      return
    }

    completionHandler(request)
  }
}
