//
//  TrackingStartsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaIntents

// MARK: - TrackingStartsTests

/// Pins that starts of Tracking take turns per Mode across their whole end-then-request step, so
/// overlapping starts of one Mode leave one activity, while starts of other Modes never wait.
///
/// Everything runs on the main actor, as every start does. The test waits for a held end, and for
/// a second start to be called (`Signal`), before it releases the end, so each interleaving below
/// is the only one possible.
@MainActor
struct TrackingStartsTests {
  @Test
  func `Overlapping starts of one Mode leave exactly one activity`() async {
    let starts: TrackingStarts = .init()
    let activities: FakeActivities = .init(running: [.init(id: "A", mode: .salmonRun)])

    activities.holdsEnds = true
    let first = Task { await starts.run(.salmonRun) { await activities.replace(.salmonRun, with: "B") } }
    await activities.waitUntilEndIsHeld()
    // Without turns, this start would also find A running and end it, and both would request.
    let called: Signal = .init()
    let second = Task {
      called.raise()
      await starts.run(.salmonRun) { await activities.replace(.salmonRun, with: "C") }
    }
    await called.wait()
    activities.releaseEnds()
    await first.value
    await second.value

    #expect(activities.running.map(\.id) == ["C"])
  }

  @Test
  func `A start of another Mode does not wait for one in flight`() async {
    let starts: TrackingStarts = .init()
    let activities: FakeActivities = .init(running: [.init(id: "A", mode: .salmonRun)])

    activities.holdsEnds = true
    let salmonRun = Task { await starts.run(.salmonRun) { await activities.replace(.salmonRun, with: "B") } }
    await activities.waitUntilEndIsHeld()
    await starts.run(.battle(.x)) { await activities.replace(.battle(.x), with: "X") }

    #expect(activities.running.map(\.id) == ["A", "X"])
    activities.releaseEnds()
    await salmonRun.value
    #expect(activities.running.map(\.id) == ["X", "B"])
  }
}

// MARK: - FakeActivities

/// Live Activities as a start sees them, with a controllable suspension point: while `holdsEnds`
/// is set, each end waits until the test releases it.
@MainActor
final private class FakeActivities {
  struct Activity {
    let id: String
    let mode: Mode
  }

  private(set) var running: [Activity]
  /// Whether an end waits for `releaseEnds()`.
  var holdsEnds: Bool = false
  private var heldEnds: [CheckedContinuation<Void, Never>] = []

  init(running: [Activity]) {
    self.running = running
  }

  /// What a start does inside its turn: ends every running activity of `mode`, then requests
  /// `id`.
  func replace(_ mode: Mode, with id: String) async {
    for activity in running where activity.mode == mode {
      await end(activity.id)
    }
    running.append(Activity(id: id, mode: mode))
  }

  func waitUntilEndIsHeld() async {
    while heldEnds.isEmpty {
      await Task.yield()
    }
  }

  /// Lets every held end finish, and every later one run through.
  func releaseEnds() {
    holdsEnds = false
    heldEnds.forEach { $0.resume() }
    heldEnds = []
  }

  private func end(_ id: String) async {
    if holdsEnds {
      await withCheckedContinuation { heldEnds.append($0) }
    }
    running.removeAll { $0.id == id }
  }
}
