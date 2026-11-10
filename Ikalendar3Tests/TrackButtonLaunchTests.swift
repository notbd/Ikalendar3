//
//  TrackButtonLaunchTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG && os(iOS)
import Testing
@testable import Ikalendar3

/// Pins when a Debug launch hides the track button: in an unrebased fixture launch, whose data
/// stays in its own process while Tracking would run on the shared cache and the network.
struct TrackButtonLaunchTests {
  static private let fixture = [
    "Ikalendar3", "--fixture", "normalDay", "--fixture-folder", "/tmp", "--fixture-instant", "2026-10-20T13:59:50Z",
  ]

  @Test
  func `An unrebased fixture launch hides the track button`() {
    #expect(DebugLaunch.hidesTrackButton(Self.fixture))
  }

  @Test
  func `A rebased fixture launch and a normal launch show it`() {
    #expect(!DebugLaunch.hidesTrackButton(Self.fixture + ["--fixture-rebase"]))
    #expect(!DebugLaunch.hidesTrackButton(["Ikalendar3"]))
  }
}
#endif
