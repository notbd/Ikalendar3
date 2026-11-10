//
//  Turns.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)

// MARK: - Turns

/// Turns for a step that must not interleave with itself: each step waits until every step called
/// before it has finished, across all its suspension points, so the steps run one at a time in
/// the order they were called.
///
/// The main actor alone does not do this: it runs one piece of a step at a time, and another
/// step's pieces between them. A step takes its place in line as it is called, before it first
/// suspends, so a caller on the main actor knows its step runs after every one it called before.
/// Built on every platform but watchOS, so the package tests run it on the Mac.
@MainActor
final class Turns {
  /// The steps waiting for their turn, longest first, while a step runs; `nil` while none runs.
  private var waiting: [CheckedContinuation<Void, Never>]?

  nonisolated init() { }

  /// Runs `step` in its turn and returns what it returns.
  func run<Value>(_ step: () async throws -> Value) async rethrows -> Value {
    if waiting == nil {
      waiting = []
    }
    else {
      await withCheckedContinuation { waiting?.append($0) }
    }
    defer { passTurn() }

    return try await step()
  }

  /// Hands the turn to the step that has waited longest, or frees it.
  private func passTurn() {
    guard var queue = waiting, !queue.isEmpty else {
      waiting = nil
      return
    }

    queue.removeFirst().resume()
    waiting = queue
  }
}
#endif
