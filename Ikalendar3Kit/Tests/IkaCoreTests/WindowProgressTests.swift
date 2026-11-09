//
//  WindowProgressTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct WindowProgressTests {
  /// An instant in a two-hour Rotation from the epoch, by seconds after its start, and the
  /// progress there.
  struct ProgressCase: CustomTestStringConvertible {
    let secondsIn: Int
    let timeLeft: Duration
    let sharePassed: Double

    var testDescription: String { "\(secondsIn) s in" }
  }

  @Test(arguments: [
    ProgressCase(secondsIn: 0, timeLeft: .seconds(7200), sharePassed: 0),
    ProgressCase(secondsIn: 3600, timeLeft: .seconds(3600), sharePassed: 0.5),
    ProgressCase(secondsIn: 7199, timeLeft: .seconds(1), sharePassed: 7199.0 / 7200),
    ProgressCase(secondsIn: 7200, timeLeft: .zero, sharePassed: 1),
  ])
  func `Progress gives the time left and the share of the Rotation passed`(_ progress: ProgressCase) {
    let rotation: Rotation = TestData.rotation(hours: 0 ..< 2)

    let instant = rotation.startTime.addingTimeInterval(TimeInterval(progress.secondsIn))

    #expect(rotation.progress(at: instant) == WindowProgress(
      timeLeft: progress.timeLeft,
      sharePassed: progress.sharePassed))
  }

  @Test
  func `A Big Run's progress counts its real 48 hours`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.bigRun.data())
    let bigRun = try #require(feed.salmonRun.first { $0.kind == .bigRun })

    let progress = bigRun.progress(at: date("2026-09-13T12:00:00Z"))

    #expect(progress == WindowProgress(timeLeft: .seconds(12 * 3600), sharePassed: 0.75))
  }
}
