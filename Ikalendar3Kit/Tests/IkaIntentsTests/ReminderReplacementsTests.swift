//
//  ReminderReplacementsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)
import Foundation
import Testing
@testable import IkaCore
@testable import IkaIntents

// MARK: - ReminderReplacementsTests

/// Pins that replacements of the pending reminders take turns in call order across their whole
/// read, remove and add step, so the reminders of the latest call stand.
///
/// Each test holds the first replacement at its read of the pending requests. The read answers
/// with what was pending as it was asked, as the system's answer to a request in flight does,
/// and the second replacement is called while it is held.
@MainActor
struct ReminderReplacementsTests {
  @Test
  func `A kind switched off while a replacement is in flight never comes back`() async {
    let center: FakePendingRequests = .init()
    let replacements: ReminderReplacements = .init(center: center)

    center.holdsNextRead = true
    let switchedOn = Task { await replacements.replace(with: [Self.bigRun]) }
    await center.waitUntilReadIsHeld()
    // Without turns, this replacement reads nothing pending and ends, and the held one then adds
    // the Big Run reminder after it.
    let called: Signal = .init()
    let switchedOff = Task {
      called.raise()
      await replacements.replace(with: [])
    }
    await called.wait()
    center.releaseRead()
    await switchedOn.value
    await switchedOff.value

    #expect(center.pending.isEmpty)
  }

  @Test
  func `Of two replacements, only the later one's reminders stay pending`() async {
    let center: FakePendingRequests = .init()
    let replacements: ReminderReplacements = .init(center: center)

    center.holdsNextRead = true
    let earlier = Task { await replacements.replace(with: [Self.bigRun]) }
    await center.waitUntilReadIsHeld()
    let called: Signal = .init()
    let later = Task {
      called.raise()
      await replacements.replace(with: [Self.splatfest])
    }
    await called.wait()
    center.releaseRead()
    await earlier.value
    await later.value

    #expect(center.pending == [Self.splatfest.id])
  }

  @Test
  func `A replacement leaves every notification outside the reminders' namespace`() async {
    let center: FakePendingRequests = .init(pending: ["other.notification", Self.bigRun.id])
    let replacements: ReminderReplacements = .init(center: center)

    await replacements.replace(with: [Self.splatfest])

    #expect(center.pending == ["other.notification", Self.splatfest.id])
  }

  // MARK: Reminders

  static private let bigRun: EventReminder = .init(
    id: EventReminder.namespace + "bigRun.1789171200",
    kind: .bigRun,
    fireDate: Date(timeIntervalSince1970: 1_789_171_200),
    title: "Big Run starts now",
    body: "")

  static private let splatfest: EventReminder = .init(
    id: EventReminder.namespace + "splatfest.1793404800",
    kind: .splatfest,
    fireDate: Date(timeIntervalSince1970: 1_793_404_800),
    title: "Splatfest starts now",
    body: "")
}

// MARK: - FakePendingRequests

/// Pending requests as a replacement sees them, with a controllable suspension point: while
/// `holdsNextRead` is set, the next read of the pending requests waits until the test releases
/// it, then answers with what was pending when it was asked.
@MainActor
final class FakePendingRequests: PendingRequests {
  /// The pending identifiers, in the order they were added.
  private(set) var pending: [String]
  /// Whether the next read waits for `releaseRead()`.
  var holdsNextRead = false
  private var heldRead: CheckedContinuation<Void, Never>?

  init(pending: [String] = []) {
    self.pending = pending
  }

  func pendingIdentifiers() async -> [String] {
    let answer = pending
    if holdsNextRead {
      holdsNextRead = false
      await withCheckedContinuation { heldRead = $0 }
    }
    return answer
  }

  func removePending(_ identifiers: [String]) {
    pending.removeAll { identifiers.contains($0) }
  }

  func add(_ reminder: EventReminder) async throws {
    pending.removeAll { $0 == reminder.id }
    pending.append(reminder.id)
  }

  func waitUntilReadIsHeld() async {
    while heldRead == nil {
      await Task.yield()
    }
  }

  func releaseRead() {
    heldRead?.resume()
    heldRead = nil
  }
}
#endif
