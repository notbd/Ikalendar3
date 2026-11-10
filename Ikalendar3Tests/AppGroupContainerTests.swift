//
//  AppGroupContainerTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import Testing

struct AppGroupContainerTests {
  /// Proves the test host carries its App Group entitlement, which is why simulator test runs keep
  /// automatic signing. An unsandboxed macOS process gets a container even without it.
  @Test
  func `App Group container resolves`() {
    #expect(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier) != nil)
  }
}
