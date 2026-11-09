//
//  ScheduleFormat.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - ScheduleFormat

/// How the screens and widgets write times: in the app language's locale on the device's hour
/// cycle, as `SentenceWriter` reads them aloud, and in the device's time zone.
public struct ScheduleFormat: Sendable {
  /// The app language.
  public let language: GameLanguage
  /// The time zone times are written in.
  public let timeZone: TimeZone

  public init(language: GameLanguage, timeZone: TimeZone) {
    self.language = language
    self.timeZone = timeZone
  }

  /// A window's start and end, with the weekday for a Shift, which spans days.
  public func timeRange(of window: some TimeWindow, withWeekday: Bool = false) -> String {
    let style: Date.IntervalFormatStyle = .interval.hour().minute()
    return range(of: window, in: withWeekday ? style.weekday() : style)
  }

  /// A window's start and end with their dates, for a window announced days ahead, such as a
  /// Splatfest's.
  func dateRange(of window: some TimeWindow) -> String {
    range(of: window, in: .interval.weekday().month().day().hour().minute())
  }

  /// An instant: its time on the day of `now`, else its weekday and time.
  public func time(_ instant: Date, relativeTo now: Date) -> String {
    var calendar: Calendar = .init(identifier: .gregorian)
    calendar.timeZone = timeZone
    var style: Date.FormatStyle = .init(locale: locale, calendar: calendar, timeZone: timeZone).hour().minute()
    if !calendar.isDate(instant, inSameDayAs: now) { style = style.weekday().month().day() }
    return instant.formatted(style)
  }

  private func range(of window: some TimeWindow, in style: Date.IntervalFormatStyle) -> String {
    var style: Date.IntervalFormatStyle = style.locale(locale)
    style.timeZone = timeZone
    return (window.startTime ..< window.endTime).formatted(style)
  }

  /// The language's locale on the device's hour cycle.
  private var locale: Locale {
    var components: Locale.Components = .init(identifier: language.rawValue)
    components.hourCycle = Locale.current.hourCycle
    return Locale(components: components)
  }
}
