//
//  AppGroupTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaCore

struct AppGroupTests {
  /// Pinned: the cache and the preferences live in this group's container, so a changed
  /// identifier would leave every user's data behind on update.
  @Test
  func `App Group identifier derives from the bundle identifier`() {
    #expect(AppGroup.identifier == "group.io.tianwei.ikalendar3")
  }
}
