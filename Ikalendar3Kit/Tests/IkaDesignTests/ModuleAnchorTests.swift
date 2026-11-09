//
//  ModuleAnchorTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaDesign

/// The verify script requires every test bundle to run at least one test on macOS and in the
/// iOS simulator. This one does until the module has real tests.
struct ModuleAnchorTests {
  @Test
  func `Module links and its bundle runs`() {
    _ = ModuleAnchor.self
  }
}
