//
//  SettableClockTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing

// MARK: - SettableClockTests

/// The fake clock's own contract; `AppClockTests` drive it as `AppClock`'s time source.
struct SettableClockTests {
  @Test(.timeLimit(.minutes(1)))
  func `A sleep to a deadline the clock already shows returns at once`() async throws {
    let clock: SettableClock = .init(date("2026-10-20T14:00:00Z"))

    try await clock.sleep(until: date("2026-10-20T14:00:00Z"))
    try await clock.sleep(until: date("2026-10-20T13:59:59Z"))

    #expect(!clock.isSleeping)
  }

  @Test(.timeLimit(.minutes(1)))
  func `Setting the clock ends the pending sleep`() async throws {
    let clock: SettableClock = .init(date("2026-10-20T14:00:00Z"))

    async let sleep: Void = clock.sleep(until: date("2026-10-20T14:00:01Z"))
    #expect(await clock.pendingSleep() == date("2026-10-20T14:00:01Z"))
    clock.now = date("2026-10-20T14:00:01Z")
    try await sleep

    #expect(!clock.isSleeping)
  }

  /// Previews and the fixture launch may run two `AppClock`s on one fake clock.
  @Test(.timeLimit(.minutes(1)))
  func `Setting the clock ends every pending sleep, each reported once`() async throws {
    let clock: SettableClock = .init(date("2026-10-20T14:00:00Z"))

    async let first: Void = clock.sleep(until: date("2026-10-20T14:00:01Z"))
    #expect(await clock.pendingSleep() == date("2026-10-20T14:00:01Z"))
    async let second: Void = clock.sleep(until: date("2026-10-20T14:00:02Z"))
    #expect(await clock.pendingSleep() == date("2026-10-20T14:00:02Z"))
    clock.now = date("2026-10-20T14:00:02Z")
    _ = try await (first, second)

    #expect(!clock.isSleeping)
  }
}
