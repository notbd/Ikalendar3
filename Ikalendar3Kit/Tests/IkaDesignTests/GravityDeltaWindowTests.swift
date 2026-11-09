//
//  GravityDeltaWindowTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics
import Testing
@testable import IkaDesign

/// Pins the stamp's motion filter: each push returns the sample minus the mean of the last
/// `capacity` samples, so a held tilt decays to zero and only changes show.
/// Carried over from ikalendar 2's `GravityDeltaWindowTests`.
struct GravityDeltaWindowTests {
  /// The stamp's window: 10 s at 10 Hz.
  private func makeWindow() -> GravityDeltaWindow {
    .init(windowLength: 10, updateInterval: 0.1)
  }

  @Test
  func `Window never holds more than its capacity`() {
    var window: GravityDeltaWindow = makeWindow()

    for sample in 0 ..< 150 {
      _ = window.push(CGFloat(sample))
    }

    #expect(window.samples.count == 100)
    #expect(window.samples.first == 50) // the oldest 50 were dropped
  }

  @Test
  func `First sample yields a zero delta`() {
    var window: GravityDeltaWindow = makeWindow()

    #expect(window.push(0.7) == 0)
  }

  @Test
  func `A steady tilt settles to a zero delta`() {
    var window: GravityDeltaWindow = makeWindow()
    var delta: CGFloat = .nan

    for _ in 0 ..< 100 {
      delta = window.push(0.4)
    }

    #expect(abs(delta) < 1e-12)
  }

  @Test
  func `A sudden tilt produces a delta that decays back to zero`() {
    var window: GravityDeltaWindow = makeWindow()
    for _ in 0 ..< 100 {
      _ = window.push(0)
    }

    // 0.5 against 99 zeros: the mean is 0.005.
    let first: CGFloat = window.push(0.5)
    #expect(abs(first - 0.495) < 1e-12)

    var deltas: [CGFloat] = [first]
    for _ in 0 ..< 99 {
      deltas.append(window.push(0.5))
    }

    #expect(zip(deltas, deltas.dropFirst()).allSatisfy { $0 > $1 })
    #expect(deltas.last == 0) // the last zero has left the window
  }

  @Test
  func `Capacity derives from the window length and the update interval`() {
    #expect(GravityDeltaWindow(windowLength: 10, updateInterval: 0.1).capacity == 100)
    #expect(GravityDeltaWindow().capacity == 100)
  }
}
