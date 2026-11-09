//
//  Splatfest+Phase.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Splatfest.Phase

extension Splatfest {
  /// Where a Splatfest stands at an instant. It follows from the start, midterm and end times,
  /// so it changes on time without a fetch.
  public enum Phase: Hashable, Sendable {
    /// In the feed and not started.
    case announced
    /// From the start to the midterm time.
    case firstHalf
    /// From the midterm time to the end, with Tricolor Turf War on `tricolorStages`.
    case secondHalf
    /// Ended.
    case over
  }

  /// The phase at `instant`.
  public func phase(at instant: Date) -> Phase {
    if instant < startTime { .announced }
    else if instant < midtermTime { .firstHalf }
    else if instant < endTime { .secondHalf }
    else { .over }
  }
}
