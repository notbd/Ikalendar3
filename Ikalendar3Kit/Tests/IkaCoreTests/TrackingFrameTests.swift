//
//  TrackingFrameTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

struct TrackingFrameTests {
  /// A render of Regular Battle Tracking built at hour 1, which carries the Rotations of hours 0
  /// to 2, 2 to 4 and 4 to 6: the first boundary (the stale date) is hour 2, the second hour 4.
  struct RenderCase: CustomTestStringConvertible {
    let hour: Double
    let isStale: Bool
    /// The carried Rotations shown as current and next, by index.
    let current: Int?
    let next: Int?
    let reminder: TrackingReminder?

    var testDescription: String { "hour \(hour)\(isStale ? ", stale" : "")" }
  }

  @Test(arguments: [
    // Before the first boundary: the current Rotation, flag or not.
    RenderCase(hour: 1, isStale: false, current: 0, next: 1, reminder: nil),
    RenderCase(hour: 1.99, isStale: true, current: 0, next: 1, reminder: nil),
    // The render the stale date triggers may be the last before the following switch.
    RenderCase(hour: 2, isStale: true, current: 1, next: 2, reminder: .nextSwitchNeedsRefresh),
    RenderCase(hour: 3.99, isStale: true, current: 1, next: 2, reminder: .nextSwitchNeedsRefresh),
    // A render without the flag after the first boundary.
    RenderCase(hour: 2, isStale: false, current: 1, next: 2, reminder: nil),
    // Past the second boundary the schedule is out of date, flag or not: the third Rotation,
    // never the second.
    RenderCase(hour: 4, isStale: true, current: 2, next: nil, reminder: .scheduleOutOfDate),
    RenderCase(hour: 5, isStale: true, current: 2, next: nil, reminder: .scheduleOutOfDate),
    RenderCase(hour: 5, isStale: false, current: 2, next: nil, reminder: .scheduleOutOfDate),
    // Past the last carried Rotation: nothing is current.
    RenderCase(hour: 6, isStale: true, current: nil, next: nil, reminder: .scheduleOutOfDate),
    RenderCase(hour: 9, isStale: false, current: nil, next: nil, reminder: .scheduleOutOfDate),
  ])
  func `A view picks the carried Rotation and the reminder by render time and the stale flag`(
    _ render: RenderCase)
    throws
  {
    let windows: [Rotation] = (0 ..< 4).map { TestData.rotation(hours: $0 * 2 ..< $0 * 2 + 2) }
    let feed: ScheduleFeed = TestData.feed(regularBattle: windows)
    let content = feed.trackingContent(of: .battle(.regular), at: TestData.instant(hours: 1))
    let rotations = try #require(content.battleRotations)
    try #require(rotations.count == 3)

    let renderTime: Date = TestData.instant(hours: render.hour)
    let frame: TrackingFrame<TrackedRotation> = .init(rotations, at: renderTime, isStale: render.isStale)

    #expect(frame.current == render.current.map { rotations[$0] })
    #expect(frame.next == render.next.map { rotations[$0] })
    #expect(frame.reminder == render.reminder)
  }
}
