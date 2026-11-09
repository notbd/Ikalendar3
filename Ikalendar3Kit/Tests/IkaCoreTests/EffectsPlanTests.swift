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

  /// The plan after one refresh of an engine on the test's directory.
  @discardableResult
  private func planAfterRefresh() async -> EffectsPlan {
    await EffectsPlan(after: RefreshEngine(directory: directory, transport: transport, clock: clock).refresh())
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
}
