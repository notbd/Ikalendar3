//
//  ScriptedTransport.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import Synchronization

// MARK: - ScriptedTransport

/// A transport that answers from a script instead of the network and records every request it
/// receives. Each address answers with the reply last scripted for it, as often as it is asked;
/// an address with no script answers as if the network were gone.
final public class ScriptedTransport: HTTPTransport {
  private struct State {
    var replies: [URL: Reply] = [:]
    var requests: [URLRequest] = []
    var isHolding = false
    var held: [CheckedContinuation<Void, Never>] = []
  }

  private let state: Mutex<State> = .init(.init())

  /// A transport with nothing scripted yet.
  public init() { }

  /// Every request received so far, in order.
  public var requests: [URLRequest] {
    state.withLock(\.requests)
  }

  /// Answers every later request to an address with a reply.
  public func reply(to url: URL, with reply: Reply) {
    state.withLock { $0.replies[url] = reply }
  }

  /// Keeps every later request in flight until `release()`: recorded, but not answered, so a
  /// test can act while it is outstanding. A held request ignores cancellation until released.
  public func hold() {
    state.withLock { $0.isHolding = true }
  }

  /// Answers every held request and stops holding.
  public func release() {
    let held = state.withLock { state in
      state.isHolding = false
      defer { state.held = [] }
      return state.held
    }
    for request in held {
      request.resume()
    }
  }

  @concurrent
  public func send(_ request: URLRequest) async throws -> HTTPResponse {
    let reply = state.withLock { state in
      state.requests.append(request)
      return request.url.flatMap { state.replies[$0] }
    }
    await withCheckedContinuation { continuation in
      let isHeld = state.withLock { state in
        if state.isHolding { state.held.append(continuation) }
        return state.isHolding
      }
      if !isHeld { continuation.resume() }
    }

    switch reply ?? .failure(URLError(.notConnectedToInternet)) {
      case .ok(let body, let etag):
        return HTTPResponse(status: 200, headers: etag.map { ["ETag": $0] } ?? [:], body: body)

      case .notModified:
        return HTTPResponse(status: 304)

      case .status(let status):
        return HTTPResponse(status: status)

      case .failure(let error):
        throw error

      case .hang:
        // Never answers: sleeps until the caller gives up and cancels.
        try await Task.sleep(for: .seconds(3600))
        throw URLError(.timedOut)
    }
  }
}

// MARK: ScriptedTransport.Reply

extension ScriptedTransport {
  /// How an address answers.
  public enum Reply: Sendable {
    /// A 200 with a body, such as a recorded payload, and the ETag the server would send.
    case ok(Data, etag: String?)
    /// A 304 Not Modified.
    case notModified
    /// Any other status with no body, such as a 500 server error.
    case status(Int)
    /// No answer: the request fails with a transport error.
    case failure(URLError)
    /// No answer ever: the request hangs until it is cancelled.
    case hang
  }
}
