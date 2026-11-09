//
//  RefreshTestSupport.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
@testable import IkaCore

extension RefreshEngine {
  /// An engine on a test's directory, as a new process would build it: the scripted network, the
  /// settable clock and English as the app language.
  convenience init(directory: URL, transport: ScriptedTransport, clock: SettableClock) {
    self.init(
      client: FeedClient(
        transport: transport,
        cache: FeedCache(directory: directory),
        appVersion: "1.0.0",
        now: { [clock] in clock.now }),
      language: .enUS)
  }
}

extension ScriptedTransport {
  /// Answers each feed an English engine refreshes with a 200 and its recorded payload.
  func scriptFeeds(schedules: Fixture = .normalDay) throws {
    try reply(to: Feed.schedules.url, with: .ok(schedules.data(), etag: #""\#(schedules)""#))
    try reply(to: Feed.festivals.url, with: .ok(Fixture.festivals.data(), etag: #""festivals""#))
    try reply(to: Feed.locale(.enUS).url, with: .ok(Fixture.localeEnUS.data(), etag: #""en-US""#))
  }

  /// Answers each feed an English engine refreshes the same way.
  func replyToFeeds(with reply: Reply) {
    for feed in [Feed.schedules, .festivals, .locale(.enUS)] {
      self.reply(to: feed.url, with: reply)
    }
  }
}
