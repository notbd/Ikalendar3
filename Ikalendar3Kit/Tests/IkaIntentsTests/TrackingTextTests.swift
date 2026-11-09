//
//  TrackingTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import IkaCore
import Testing
@testable import IkaIntents

// MARK: - TrackingTextTests

/// The Live Activity's reminders, written in `IkaCore`, tell the player to tap Refresh; the
/// button, labelled here, must carry that word in every language.
struct TrackingTextTests {
  @Test(arguments: GameLanguage.allCases)
  func `Each reminder names the Refresh button by its own word`(language: GameLanguage) {
    let refresh = TrackingText.refresh.text(in: language)

    #expect(refresh != TrackingText.refresh.rawValue || language.rawValue.hasPrefix("en"))
    for reminder in TrackingReminder.allCases {
      #expect(reminder.text(in: language).contains(refresh), "\(reminder)")
    }
  }
}
#endif
