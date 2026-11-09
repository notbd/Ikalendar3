//
//  EffectsPlanTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - EffectsPlanTests

/// The effects a run of the effects shell applies after its refresh, planned from real refreshes
/// on the scripted network.
@MainActor
final class EffectsPlanTests {
  private let directory: URL
  private let transport: ScriptedTransport = .init()
  private let clock: SettableClock = .init(date("2026-10-20T12:05:00Z"))

  init() throws {
    directory = try makeTestDirectory()
  }

  deinit {
    try? FileManager.default.removeItem(at: directory)
  }

  /// The plan after one refresh of an engine on the test's directory, with `tracking` running.
  @discardableResult
  private func planAfterRefresh(tracking: [RunningTracking] = []) async -> EffectsPlan {
    let result = await RefreshEngine(directory: directory, transport: transport, clock: clock).refresh()
    return EffectsPlan(after: result, tracking: tracking, at: clock.now)
  }

  // MARK: - Widget timelines

  @Test
  func `Widget timelines reload after a refresh that commits a new body`() async throws {
    try transport.scriptFeeds()

    let plan = await planAfterRefresh()

    #expect(plan.reloadsWidgetTimelines)
  }

  /// A 304 renews the fetch time, which the widgets show beside the app's.
  @Test
  func `Widget timelines reload after a refresh a 304 confirms`() async throws {
    try transport.scriptFeeds()
    await planAfterRefresh()
    transport.replyToFeeds(with: .notModified)
    clock.now = date("2026-10-20T13:05:00Z")

    let plan = await planAfterRefresh()

    #expect(plan.reloadsWidgetTimelines)
  }

  @Test(arguments: [
    ScriptedTransport.Reply.status(500),
    .ok(Data("<html>Bad gateway</html>".utf8), etag: #""e1""#),
    .failure(URLError(.notConnectedToInternet)),
  ])
  func `Widget timelines do not reload after a failed refresh`(_ reply: ScriptedTransport.Reply) async {
    transport.replyToFeeds(with: reply)

    let plan = await planAfterRefresh()

    #expect(!plan.reloadsWidgetTimelines)
  }

  @Test
  func `Widget timelines do not reload after a refresh the gate kept from the network`() async throws {
    try transport.scriptFeeds()
    await planAfterRefresh()
    clock.now = date("2026-10-20T12:35:00Z")

    let plan = await planAfterRefresh()

    #expect(transport.requests.count == 3)
    #expect(!plan.reloadsWidgetTimelines)
  }

  /// The confirmed feeds' fetch times moved, so the widgets must read them again.
  @Test
  func `Widget timelines reload when one feed fails and the others are confirmed`() async throws {
    try transport.scriptFeeds()
    await planAfterRefresh()
    transport.replyToFeeds(with: .notModified)
    transport.reply(to: Feed.schedules.url, with: .status(500))
    clock.now = date("2026-10-20T13:05:00Z")

    let plan = await planAfterRefresh()

    #expect(plan.reloadsWidgetTimelines)
  }

  // MARK: - Tracking

  /// X Battle and Salmon Run, Tracked since 11:30 UTC on the normal day.
  private let tracking: [RunningTracking] = [
    RunningTracking(id: "x", mode: .battle(.x), startTime: date("2026-10-20T11:30:00Z")),
    RunningTracking(id: "salmon", mode: .salmonRun, startTime: date("2026-10-20T11:30:00Z")),
  ]

  @Test
  func `Every running Tracking is re-armed from the cache, its stale date at the current item's end`() async throws {
    try transport.scriptFeeds()

    let plan = await planAfterRefresh(tracking: tracking)

    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())
    #expect(plan.tracking == [
      "x": .update(TrackingState(content: feed.trackingContent(of: .battle(.x), at: clock.now), fetchTime: clock.now)),
      "salmon": .update(TrackingState(
        content: feed.trackingContent(of: .salmonRun, at: clock.now),
        fetchTime: clock.now)),
    ])
    #expect(plan.tracking["x"]?.state?.staleDate == date("2026-10-20T14:00:00Z"))
    #expect(plan.tracking["salmon"]?.state?.staleDate == date("2026-10-20T16:00:00Z"))
  }

  /// A Refresh inside the hour sends no request, yet still moves the activity to the item on now.
  @Test
  func `A run the gate kept from the network still re-arms every running Tracking`() async throws {
    try transport.scriptFeeds()
    await planAfterRefresh()
    clock.now = date("2026-10-20T12:55:00Z")

    let plan = await planAfterRefresh(tracking: tracking)

    #expect(transport.requests.count == 3)
    #expect(plan.tracking["x"]?.state?.staleDate == date("2026-10-20T14:00:00Z"))
    #expect(plan.tracking["x"]?.state?.fetchTime == date("2026-10-20T12:05:00Z"))
    clock.now = date("2026-10-20T14:05:00Z")
    let later = await planAfterRefresh(tracking: tracking)
    #expect(later.tracking["x"]?.state?.staleDate == date("2026-10-20T16:00:00Z"))
  }

  @Test
  func `A failed refresh re-arms every running Tracking from the last good data`() async throws {
    try transport.scriptFeeds()
    await planAfterRefresh()
    transport.replyToFeeds(with: .status(500))
    clock.now = date("2026-10-20T14:05:00Z")

    let plan = await planAfterRefresh(tracking: tracking)

    #expect(plan.tracking["x"]?.state?.staleDate == date("2026-10-20T16:00:00Z"))
    #expect(plan.tracking["x"]?.state?.fetchTime == date("2026-10-20T12:05:00Z"))
  }

  @Test
  func `A running Tracking is left as it is while the cache holds no schedules feed`() async {
    transport.replyToFeeds(with: .failure(URLError(.notConnectedToInternet)))

    let plan = await planAfterRefresh(tracking: tracking)

    #expect(plan.tracking.isEmpty)
  }

  @Test
  func `Tracking ends eight hours after it starts, instead of being re-armed`() async throws {
    try transport.scriptFeeds()
    let started = date("2026-10-20T04:05:00Z")
    let tracking = [
      RunningTracking(id: "ending", mode: .battle(.regular), startTime: started),
      RunningTracking(id: "running", mode: .battle(.regular), startTime: started.addingTimeInterval(1)),
    ]

    let plan = await planAfterRefresh(tracking: tracking)

    #expect(plan.tracking["ending"] == .end)
    #expect(plan.tracking["running"]?.state != nil)
  }

  // MARK: - Background run

  /// The app asked for a run two hours on as it last moved to the background.
  @Test
  func `A run with no Tracking running leaves the background task's pending request as it is`() async throws {
    try transport.scriptFeeds()

    let plan = await planAfterRefresh()

    #expect(plan.nextBackgroundRun == nil)
  }

  @Test
  func `A run that ends the last Tracking asks for the background task two hours on`() async throws {
    try transport.scriptFeeds()

    let plan = await planAfterRefresh(tracking: [
      RunningTracking(id: "ending", mode: .salmonRun, startTime: date("2026-10-20T04:00:00Z")),
    ])

    #expect(plan.nextBackgroundRun == date("2026-10-20T14:05:00Z"))
  }

  @Test
  func `The background task runs again at the next boundary of a running Tracking`() async throws {
    try transport.scriptFeeds()
    clock.now = date("2026-10-20T13:15:00Z")

    let plan = await planAfterRefresh(tracking: tracking)

    #expect(plan.nextBackgroundRun == date("2026-10-20T14:00:00Z"))
  }

  @Test
  func `The background task runs again when a running Tracking ends, if that comes first`() async throws {
    try transport.scriptFeeds()
    // Ends at 12:35, before the current Rotation's 14:00 boundary and the two hours.
    let started = date("2026-10-20T04:35:00Z")

    let plan = await planAfterRefresh(tracking: [
      RunningTracking(id: "ending soon", mode: .battle(.x), startTime: started),
    ])

    #expect(plan.nextBackgroundRun == date("2026-10-20T12:35:00Z"))
  }

  @Test
  func `A boundary two hours or more away leaves the background task's two hours`() {
    let now = date("2026-10-20T13:15:00Z")
    let tracking = [RunningTracking(id: "a", mode: .salmonRun, startTime: date("2026-10-20T13:00:00Z"))]

    #expect(EffectsPlan.nextBackgroundRun(after: now, tracking: tracking, staleDates: [date("2026-10-20T16:00:00Z")]) ==
      date("2026-10-20T15:15:00Z"))
    #expect(EffectsPlan.nextBackgroundRun(after: now, tracking: tracking, staleDates: [
      date("2026-10-20T16:00:00Z"),
      date("2026-10-20T14:00:00Z"),
    ]) == date("2026-10-20T14:00:00Z"))
  }
}
