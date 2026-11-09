//
//  Countdown.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - Countdown

/// A time left as every ticking countdown splits it: whole seconds, rounded up so a running
/// window never reads zero, in hours, which run past a day, minutes and seconds. Each Style and
/// `SentenceWriter.countdown(_:)` write these parts their own way, so all of them show the same
/// second.
public struct Countdown: Hashable, Sendable {
  /// The whole hours, past a day too.
  public let hours: Int
  /// The minutes past the hour.
  public let minutes: Int
  /// The seconds past the minute.
  public let seconds: Int

  /// `timeLeft` split into its parts; a time left of zero or less reads zero.
  public init(_ timeLeft: Duration) {
    // On the integer components: dividing by a second goes through `Double`, which reads some
    // whole seconds a hair above them, and rounding up would add a second.
    let (wholeSeconds, attoseconds) = timeLeft.components
    let total: Int = max(Int(wholeSeconds) + (attoseconds > 0 ? 1 : 0), 0)
    let (hours, secondsPastHour) = total.quotientAndRemainder(dividingBy: 3600)
    let (minutes, seconds) = secondsPastHour.quotientAndRemainder(dividingBy: 60)
    self.hours = hours
    self.minutes = minutes
    self.seconds = seconds
  }
}
