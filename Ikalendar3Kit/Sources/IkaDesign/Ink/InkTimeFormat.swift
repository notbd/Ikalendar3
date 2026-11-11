//
//  InkTimeFormat.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import Foundation
import IkaCore

// MARK: - InkTimeFormat

/// How Ink's screens write times on their black tags, one way for every window: a time of day,
/// with its weekday when it is not on today, and with its date too from a week away, where a
/// weekday alone would name two days. Times are in the app language's locale on the device's hour
/// cycle and in the player's time zone; views take it from `TimeSettings`.
struct InkTimeFormat {
  /// The app language.
  let language: GameLanguage
  /// The time zone times are written in.
  let timeZone: TimeZone
  /// Whether times read on a 12- or a 24-hour clock.
  let hourCycle: Locale.HourCycle

  /// A window's start and end, joined as the game joins a range. A window shorter than a day (a
  /// Rotation, a Challenge's window) is "10:00 PM - 12:00 AM", its start with its day when that
  /// is not today: "Wed 12:00 AM - 2:00 AM". A longer one (a Shift, a Splatfest) names the day
  /// of both ends: "Tue 12:00 PM - Thu 4:00 AM".
  func range(of window: some TimeWindow, now: Date) -> String {
    let isWithinADay: Bool = window.endTime.timeIntervalSince(window.startTime) < Self.day
    let start: String = isWithinADay ? time(window.startTime, now: now) : dayAndTime(window.startTime, now: now)
    let end: String = isWithinADay ? timeOfDay(window.endTime) : dayAndTime(window.endTime, now: now)
    return ScreenText.timeRange.text(in: language, start, end)
  }

  /// An instant: its time on the day of `now`, else its day and time.
  func time(_ instant: Date, now: Date) -> String {
    calendar.isDate(instant, inSameDayAs: now) ? timeOfDay(instant) : dayAndTime(instant, now: now)
  }

  // MARK: Parts

  /// The seconds in a day.
  static private let day: TimeInterval = 24 * 60 * 60

  /// `instant`'s time of day: "10:00 PM".
  private func timeOfDay(_ instant: Date) -> String {
    instant.formatted(style)
  }

  /// `instant`'s weekday and time, "Tue 12:00 PM", with its date from a week away from `now`:
  /// "Tue, 11/3, 12:00 PM".
  private func dayAndTime(_ instant: Date, now: Date) -> String {
    let style: Date.FormatStyle = style.weekday(.abbreviated)
    let days: Int = calendar
      .dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: instant))
      .day ?? 0
    return instant.formatted(abs(days) < 7 ? style : style.month(.defaultDigits).day())
  }

  /// Hours and minutes in the language's locale on the hour cycle, in the time zone.
  private var style: Date.FormatStyle {
    var components: Locale.Components = .init(identifier: language.rawValue)
    components.hourCycle = hourCycle
    return Date.FormatStyle(locale: Locale(components: components), calendar: calendar, timeZone: timeZone)
      .hour()
      .minute()
  }

  /// The Gregorian calendar in the time zone, which decides where a day starts.
  private var calendar: Calendar {
    var calendar: Calendar = .init(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
  }
}

extension TimeSettings {
  /// How Ink's screens write times in `language`.
  func inkFormat(_ language: GameLanguage) -> InkTimeFormat {
    InkTimeFormat(language: language, timeZone: timeZone, hourCycle: hourCycle)
  }
}
#endif
