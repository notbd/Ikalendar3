//
//  URLSessionTransportTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Synchronization
import Testing
@testable import IkaCore

// MARK: - URLSessionTransportTests

/// The shipping transport against canned answers, never the real network. Serialized because the
/// canned answers are static, shared by every session that uses the stub.
@Suite(.serialized)
struct URLSessionTransportTests {
  private let url = Feed.schedules.url

  /// A transport whose every request is answered from `answers`, by address.
  private func makeTransport(answering answers: [URL: StubURLProtocol.Answer]) -> URLSessionTransport {
    StubURLProtocol.state.withLock { $0 = .init(answers: answers) }
    let configuration: URLSessionConfiguration = .ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return URLSessionTransport(configuration: configuration)
  }

  @Test(arguments: [200, 304, 500])
  func `An answer comes back with its status, headers and body as sent`(status: Int) async throws {
    let body: Data = .init(#"{"data":{}}"#.utf8)
    let answer: StubURLProtocol.Answer = .http(status: status, headers: ["ETag": #"W/"dce9980d""#], body: body)
    let transport = makeTransport(answering: [url: answer])

    let response = try await transport.send(URLRequest(url: url))

    #expect(response.status == status)
    #expect(response.value(forHTTPHeaderField: "etag") == #"W/"dce9980d""#)
    #expect(response.body == body)
  }

  @Test
  func `The request's headers reach the network unchanged`() async throws {
    let transport = makeTransport(answering: [url: .http(status: 304, headers: [:], body: Data())])
    var outgoing: URLRequest = .init(url: url)
    outgoing.setValue(
      "ikalendar3/1.0.0 (+https://ikalendar.app/3; ikalendar3@tianwei.io)",
      forHTTPHeaderField: "User-Agent")
    outgoing.setValue(#"W/"dce9980d""#, forHTTPHeaderField: "If-None-Match")

    _ = try await transport.send(outgoing)

    let sent = try #require(StubURLProtocol.state.withLock(\.requests).first)
    #expect(
      sent.value(forHTTPHeaderField: "User-Agent")
        == "ikalendar3/1.0.0 (+https://ikalendar.app/3; ikalendar3@tianwei.io)")
    #expect(sent.value(forHTTPHeaderField: "If-None-Match") == #"W/"dce9980d""#)
  }

  @Test
  func `No answer throws`() async {
    let transport = makeTransport(answering: [url: .failure(URLError(.notConnectedToInternet))])

    await #expect(throws: URLError.self) {
      try await transport.send(URLRequest(url: url))
    }
  }

  // MARK: Redirects

  /// An allowed hop that redirects again, to `secondHop`.
  static let hop: URL = .init(string: "https://assets.splatoon3.ink/hop")!
  static let secondHop: URL = .init(string: "https://example.com/hop")!

  /// Where the feed's address redirects to, and the addresses requested before the refusal: a
  /// third host, a downgrade to HTTP, a host that only starts like one of the two, and an allowed
  /// hop whose own redirect leaves them.
  static let refusedRedirects: [(target: URL, requested: [URL])] = [
    (URL(string: "https://example.com/data/schedules.json")!, [Feed.schedules.url]),
    (URL(string: "http://splatoon3.ink/data/schedules.json")!, [Feed.schedules.url]),
    (URL(string: "https://splatoon3.ink.example.com/data/schedules.json")!, [Feed.schedules.url]),
    (hop, [Feed.schedules.url, hop]),
  ]

  @Test(arguments: refusedRedirects)
  func `A redirect off the two hosts is refused before its target receives a request`(
    target: URL,
    requested: [URL])
    async throws
  {
    var answers: [URL: StubURLProtocol.Answer] = [url: .redirect(to: target), Self.hop: .redirect(to: Self.secondHop)]
    // A followed redirect would be answered, and its request recorded.
    for followed in [target, Self.secondHop] where answers[followed] == nil {
      answers[followed] = .http(status: 200, headers: [:], body: Data())
    }
    let transport = makeTransport(answering: answers)

    let response = try await transport.send(URLRequest(url: url))

    // The refused redirect is the answer, a status the feed client counts as failed.
    #expect(response.status == 302)
    #expect(StubURLProtocol.state.withLock(\.requests).compactMap(\.url) == requested)
  }

  @Test
  func `A redirect within the two hosts is followed`() async throws {
    let moved: URL = Source.feeds.appending(path: "moved/schedules.json")
    let body: Data = .init(#"{"data":{}}"#.utf8)
    let transport = makeTransport(answering: [
      url: .redirect(to: moved),
      moved: .http(status: 200, headers: [:], body: body),
    ])

    let response = try await transport.send(URLRequest(url: url))

    #expect(response.status == 200)
    #expect(response.body == body)
    #expect(StubURLProtocol.state.withLock(\.requests).compactMap(\.url) == [url, moved])
  }
}

// MARK: - StubURLProtocol

/// Answers every request with the canned answer for its address instead of going to the network,
/// and keeps every request it received, in order. An address with no answer fails.
final private class StubURLProtocol: URLProtocol {
  enum Answer {
    case http(status: Int, headers: [String: String], body: Data)
    /// A 302 to another address, which the session follows or refuses.
    case redirect(to: URL)
    case failure(URLError)
  }

  struct State {
    var answers: [URL: Answer] = [:]
    var requests: [URLRequest] = []
  }

  static let state: Mutex<State> = .init(.init())

  override static func canInit(with _: URLRequest) -> Bool {
    true
  }

  override static func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    let answer = Self.state.withLock { state in
      state.requests.append(request)
      return request.url.flatMap { state.answers[$0] }
    }
    switch answer {
      case .http(let status, let headers, let body):
        if let response = response(status: status, headers: headers) {
          client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)

      case .redirect(let target):
        guard let response = response(status: 302, headers: ["Location": target.absoluteString]) else { return }

        // As a server's redirect: the session asks its delegate, then loads the target in a new
        // protocol or, refused, ends with this answer.
        client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: target), redirectResponse: response)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)

      case .failure(let error):
        client?.urlProtocol(self, didFailWithError: error)

      case nil:
        client?.urlProtocol(self, didFailWithError: URLError(.unknown))
    }
  }

  /// An answer to the request with a status and header fields.
  private func response(status: Int, headers: [String: String]) -> HTTPURLResponse? {
    request.url.flatMap { HTTPURLResponse(url: $0, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers) }
  }

  override func stopLoading() { }
}
