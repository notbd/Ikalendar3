//
//  InkPanelEntryTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore
@testable import IkaDesign

/// Pins which of Ink's panels is featured and how each is tagged.
struct InkPanelEntryTests {
  /// A two-hour window starting `hours` after the epoch.
  struct Window: TimeWindow, Hashable {
    let startTime: Date
    let endTime: Date

    init(hours: Double) {
      startTime = Date(timeIntervalSince1970: hours * 3600)
      endTime = startTime.addingTimeInterval(2 * 3600)
    }
  }

  static let progress: WindowProgress = .init(timeLeft: .seconds(1800), sharePassed: 0.75)

  @Test
  func `The running item leads as Now, then Next, then the later items untagged`() {
    let current: Running<Window> = .init(item: Window(hours: 0), progress: Self.progress)

    let entries: [InkPanelEntry<Window>] = InkPanelEntry.entries(
      current: .running(current),
      next: Window(hours: 2),
      later: [Window(hours: 4), Window(hours: 6)])

    #expect(entries.map(\.place) == [.now(Self.progress), .next, .later, .later])
    #expect(entries.map(\.item) == [Window(hours: 0), Window(hours: 2), Window(hours: 4), Window(hours: 6)])
  }

  @Test(arguments: [OnNow<Window>.nothingCurrent, .paused(returnTime: Date(timeIntervalSince1970: 7200))])
  func `With nothing running, the next item still reads Next`(current: OnNow<Window>) {
    let entries: [InkPanelEntry<Window>] = InkPanelEntry.entries(
      current: current,
      next: Window(hours: 2),
      later: [Window(hours: 4)])

    #expect(entries.map(\.place) == [.next, .later])
  }

  @Test
  func `An item keeps its panel's identity when it turns from Next into Now`() {
    let before: [InkPanelEntry<Window>] = InkPanelEntry.entries(
      current: .nothingCurrent,
      next: Window(hours: 2),
      later: [])
    let after: [InkPanelEntry<Window>] = InkPanelEntry.entries(
      current: .running(Running(item: Window(hours: 2), progress: Self.progress)),
      next: nil,
      later: [])

    #expect(before[0].id == after[0].id)
  }

  @Test
  func `A Challenge window reads Now, Next or untagged, and an ended one has no place`() {
    #expect(InkPanelPlace(ChallengeScreen.WindowMark.current(Self.progress)) == .now(Self.progress))
    #expect(InkPanelPlace(ChallengeScreen.WindowMark.next) == .next)
    #expect(InkPanelPlace(ChallengeScreen.WindowMark.later) == .later)
    #expect(InkPanelPlace(ChallengeScreen.WindowMark.over) == nil)
  }
}
