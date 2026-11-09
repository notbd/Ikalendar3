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
}
