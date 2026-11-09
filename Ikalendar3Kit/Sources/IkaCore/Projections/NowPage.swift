//
//  NowPage.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - NowPage

/// What the watch's Now page shows at an instant: a running Splatfest on top, then one summary per
/// Mode of the Mode value, in its order. A Battle Mode the Splatfest pauses reports its pause with
/// its return time, as its summary does everywhere.
public struct NowPage: Hashable, Sendable {
  /// The Splatfest whose teams show on top while it runs, in either half; `nil` while none runs,
  /// an announced one included.
  public let splatfest: Splatfest?
  /// The summaries of the four continuous Battle Modes, then Salmon Run's.
  public let summaries: [ModeSummary]
  /// When the schedules feed shown was last confirmed.
  public let fetchTime: Date
}

extension Snapshot {
  /// The Now page at `instant`, or `nil` before the schedules feed's first good response.
  public func nowPage(at instant: Date) -> NowPage? {
    guard let schedules else { return nil }

    let runningSplatfest: Splatfest? = splatfest.flatMap { splatfest in
      switch splatfest.phase(at: instant) {
        case .firstHalf,
             .secondHalf: splatfest
        case .announced,
             .over: nil
      }
    }
    return NowPage(
      splatfest: runningSplatfest,
      summaries: Mode.allCases.compactMap { summary(of: $0, at: instant) },
      fetchTime: schedules.fetchTime)
  }
}
