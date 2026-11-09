//
//  AppClockTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Observation
import Synchronization
import Testing
@testable import IkaCore

// MARK: - AppClockTests

@MainActor
struct AppClockTests {
  /// The normal day's first Rotation boundary.
  private let boundary: Date = date("2026-10-20T14:00:00Z")

  @Test
  func `A new clock publishes the whole second its time source is in`() {
    let clock: AppClock = .init(source: ManualTimeSource(now: boundary.addingTimeInterval(-2.75)))

    #expect(clock.now == boundary.addingTimeInterval(-3))
  }

  @Test
  func `Across a Rotation boundary the clock publishes every whole second once`() async {
    let source: ManualTimeSource = .init(now: boundary.addingTimeInterval(-2.75))
    let clock: AppClock = .init(source: source)

    var published = [clock.now]
    var deadline = await source.pendingSleep()
    // A system timer may end a sleep up to its tolerance late.
    for lateness in [0, 0.04, 0.099, 0.001, 0.05] {
      #expect(deadline == clock.now.addingTimeInterval(1))
      let didPublish = await publishes(clock) {
        source.wake(at: deadline.addingTimeInterval(lateness))
        deadline = await source.pendingSleep()
      }
      #expect(didPublish)
      published.append(clock.now)
    }

    #expect(published == (-3 ... 2).map { boundary.addingTimeInterval(TimeInterval($0)) })
  }

  @Test
  func `A sleep that ends early publishes nothing and sleeps again until the same second`() async {
    let source: ManualTimeSource = .init(now: boundary.addingTimeInterval(-0.5))
    let clock: AppClock = .init(source: source)
    #expect(await source.pendingSleep() == boundary)

    var deadline: Date?
    let didPublish = await publishes(clock) {
      source.wake(at: boundary.addingTimeInterval(-0.02))
      deadline = await source.pendingSleep()
    }

    #expect(deadline == boundary)
    #expect(!didPublish)
    #expect(clock.now == boundary.addingTimeInterval(-1))
  }

  @Test
  func `A wake after a long suspension publishes the second it woke in, not the missed ones`() async {
    let source: ManualTimeSource = .init(now: boundary.addingTimeInterval(-0.5))
    let clock: AppClock = .init(source: source)
    _ = await source.pendingSleep()

    source.wake(at: boundary.addingTimeInterval(42.6))
    let deadline = await source.pendingSleep()

    #expect(clock.now == boundary.addingTimeInterval(42))
    #expect(deadline == boundary.addingTimeInterval(43))
  }

  @Test
  func `A released clock stops ticking`() async {
    let source: ManualTimeSource = .init(now: boundary)
    weak var released: AppClock?
    do {
      let clock: AppClock = .init(source: source)
      released = clock
      _ = await source.pendingSleep()
      #expect(clock.now == boundary)
    }

    #expect(released == nil)
    #expect(!source.isSleeping)
  }

  /// Whether `clock` publishes while `body` runs.
  private func publishes(_ clock: AppClock, while body: () async -> Void) async -> Bool {
    let flag: Flag = .init()
    withObservationTracking { _ = clock.now } onChange: { flag.raise() }
    await body()
    return flag.isRaised
  }
}

// MARK: - Flag

/// A flag any thread can raise.
final private class Flag: Sendable {
  private let raised: Mutex<Bool> = .init(false)

  var isRaised: Bool { raised.withLock { $0 } }

  func raise() {
    raised.withLock { $0 = true }
  }
}
