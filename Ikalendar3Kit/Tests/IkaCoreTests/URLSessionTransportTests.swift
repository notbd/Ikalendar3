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
/// canned answer is static, shared by every session that uses the stub.
@Suite(.serialized)
struct URLSessionTransportTests {
  private let url = Feed.schedules.url

  private func makeTransport(answering answer: StubURLProtocol.Answer) -> URLSessionTransport {
    StubURLProtocol.state.withLock { $0 = .init(answer: answer) }
    let configuration: URLSessionConfiguration = .ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return URLSessionTransport(configuration: configuration)
  }

  @Test(arguments: [200, 304, 500])
  func `An answer comes back with its status, headers and body as sent`(status: Int) async throws {
    let body: Data = .init(#"{"data":{}}"#.utf8)
    let transport = makeTransport(answering: .http(status: status, headers: ["ETag": #"W/"dce9980d""#], body: body))

    let response = try await transport.send(URLRequest(url: url))

    #expect(response.status == status)
    #expect(response.value(forHTTPHeaderField: "etag") == #"W/"dce9980d""#)
    #expect(response.body == body)
  }

  @Test
  func `The request's headers reach the network unchanged`() async throws {
    let transport = makeTransport(answering: .http(status: 304, headers: [:], body: Data()))
    var outgoing: URLRequest = .init(url: url)
    outgoing.setValue(
      "ikalendar3/1.0.0 (+https://ikalendar.app/3; ikalendar3@tianwei.io)",
      forHTTPHeaderField: "User-Agent")
    outgoing.setValue(#"W/"dce9980d""#, forHTTPHeaderField: "If-None-Match")

    _ = try await transport.send(outgoing)

    let request = StubURLProtocol.state.withLock(\.request)
    let sent = try #require(request)
    #expect(
      sent.value(forHTTPHeaderField: "User-Agent")
        == "ikalendar3/1.0.0 (+https://ikalendar.app/3; ikalendar3@tianwei.io)")
    #expect(sent.value(forHTTPHeaderField: "If-None-Match") == #"W/"dce9980d""#)
  }

  @Test
  func `No answer throws`() async {
    let transport = makeTransport(answering: .failure(URLError(.notConnectedToInternet)))

    await #expect(throws: URLError.self) {
      try await transport.send(URLRequest(url: url))
    }
  }
}

// MARK: - StubURLProtocol

/// Answers every request with the canned answer instead of going to the network, and keeps the
/// request it received.
final private class StubURLProtocol: URLProtocol {
  enum Answer {
    case http(status: Int, headers: [String: String], body: Data)
    case failure(URLError)
  }

  struct State {
    var answer: Answer?
    var request: URLRequest?
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
      state.request = request
      return state.answer
    }
    switch answer {
      case .http(let status, let headers, let body):
        if
          let url = request.url,
          let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)
        {
          client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)

      case .failure(let error):
        client?.urlProtocol(self, didFailWithError: error)

      case nil:
        client?.urlProtocol(self, didFailWithError: URLError(.unknown))
    }
  }

  override func stopLoading() { }
}
