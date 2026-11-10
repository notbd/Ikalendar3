//
//  TrackingActivitiesTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import ActivityKit
import Testing
@testable import IkaIntents

/// Pins which Live Activities count as a running Tracking: a dismissed one does not, so nothing
/// re-arms it and the track button's next start Tracks the Mode afresh.
struct TrackingActivitiesTests {
  @Test
  func `Active and stale activities run, dismissed and ended ones do not`() {
    #expect(TrackingActivities.isRunning(.active))
    #expect(TrackingActivities.isRunning(.stale))
    #expect(!TrackingActivities.isRunning(.dismissed))
    #expect(!TrackingActivities.isRunning(.ended))
  }
}
#endif
