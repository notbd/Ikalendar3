//
//  BackgroundRefreshTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import Foundation
import IkaIntents
import Testing

// MARK: - BackgroundRefreshTests

/// The background refresh task as the built app declares it: the system runs the task only when
/// the Info.plist permits its identifier and lists the fetch background mode.
struct BackgroundRefreshTests {
  @Test
  func `The app permits its background refresh task and declares the fetch mode`() {
    #expect(Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String] == [
      BackgroundRefresh.identifier,
    ])
    #expect(Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] == ["fetch"])
  }
}
#endif
