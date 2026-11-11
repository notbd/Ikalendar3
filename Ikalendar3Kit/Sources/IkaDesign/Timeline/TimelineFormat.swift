//
//  TimelineFormat.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import Foundation
import IkaCore

// MARK: - TimelineFormat

/// How Timeline writes times, as SplatNet 3's schedule page does: on the device's hour cycle, in
/// the app language and the player's time zone. On a 24-hour clock a time is "22:00"; on a 12-hour
/// clock it is "10 PM", its minutes written only off the hour, so the pins stay short.
struct TimelineFormat {
  /// The app language.
  let language: GameLanguage
  /// The time zone times are written in.
  let timeZone: TimeZone
  /// Whether times read on a 12- or a 24-hour clock.
  let hourCycle: Locale.HourCycle

  /// A start time's pin on the axis: "22:00" or "10 PM", its AM or PM marked as a date field so
  /// the pin can set it smaller.
  func pin(_ instant: Date) -> AttributedString {
    instant.formatted(style(time(of: instant)).attributedStyle)
  }

  /// The day mark where the axis reaches a new day: "Tue, 10/20".
  func day(_ instant: Date) -> String {
    instant.formatted(style(.init().weekday(.abbreviated).month(.defaultDigits).day()))
  }

  /// Whether `instant` falls on another day than `previous`, the start before it on the axis, so
  /// the axis marks its day. The first start always does.
  func startsNewDay(_ instant: Date, after previous: Date?) -> Bool {
    guard let previous else { return true }

    return !calendar.isDate(instant, inSameDayAs: previous)
  }

  /// An instant on the day of `now` as its time alone, else with its weekday: "8 PM",
  /// "Sun 8 PM".
  func time(_ instant: Date, relativeTo now: Date) -> String {
    calendar.isDate(instant, inSameDayAs: now)
      ? instant.formatted(style(time(of: instant)))
      : instant.formatted(style(time(of: instant).weekday(.abbreviated)))
  }

  /// A Shift's start and end with their weekdays, joined as the game joins a range:
  /// "Tue 17:00 - Thu 09:00", "Tue 5 PM - Thu 9 AM".
  func timeRange(from start: Date, to end: Date) -> String {
    range(from: start, to: end) { $0.weekday(.abbreviated) }
  }

  /// A Splatfest's start and end with their weekdays and dates, since it is announced weeks
  /// ahead: "Sat, 10/31, 09:00 - Mon, 11/2, 09:00".
  func dateRange(from start: Date, to end: Date) -> String {
    range(from: start, to: end) { $0.weekday(.abbreviated).month(.defaultDigits).day() }
  }

  /// A window's start and end alone, where a day mark above gives its day: "17:00 - 19:00",
  /// "5 PM - 7 PM".
  func hourRange(from start: Date, to end: Date) -> String {
    range(from: start, to: end) { $0 }
  }

  /// The time left as the `Countdown` every Style shows, its hours running past a day:
  /// "1:09:59".
  static func countdown(_ timeLeft: Duration) -> String {
    let countdown: Countdown = .init(timeLeft)
    return "\(countdown.hours):\(twoDigits(countdown.minutes)):\(twoDigits(countdown.seconds))"
  }

  /// `value` with a leading zero below 10.
  static private func twoDigits(_ value: Int) -> String {
    value < 10 ? "0\(value)" : "\(value)"
  }

  /// Whether times read on a 12-hour clock.
  private var isTwelveHour: Bool {
    hourCycle == .oneToTwelve || hourCycle == .zeroToEleven
  }

  /// The fields that write `instant`'s time: two-digit hours and minutes on a 24-hour clock, the
  /// hour and AM or PM on a 12-hour one, with the minutes only off the hour.
  private func time(of instant: Date) -> Date.FormatStyle {
    guard isTwelveHour else {
      return .init().hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
    }

    let hour: Date.FormatStyle = .init().hour(.defaultDigits(amPM: .abbreviated))
    return calendar.component(.minute, from: instant) == 0 ? hour : hour.minute(.twoDigits)
  }

  /// `start` and `end`, each with its time and the fields `fields` adds, joined as the game joins
  /// a range.
  private func range(
    from start: Date,
    to end: Date,
    adding fields: (Date.FormatStyle) -> Date.FormatStyle)
    -> String
  {
    ScreenText.timeRange.text(
      in: language,
      start.formatted(style(fields(time(of: start)))),
      end.formatted(style(fields(time(of: end)))))
  }

  /// `style` in the app language on the hour cycle and in the time zone.
  private func style(_ style: Date.FormatStyle) -> Date.FormatStyle {
    var components: Locale.Components = .init(identifier: language.rawValue)
    components.hourCycle = hourCycle
    var style = style.locale(Locale(components: components))
    style.timeZone = timeZone
    return style
  }

  /// The Gregorian calendar in the time zone, which decides where a day starts.
  private var calendar: Calendar {
    var calendar: Calendar = .init(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
  }
}

extension TimeSettings {
  /// How Timeline writes times in `language`: in this view's time zone and on its hour cycle.
  func timelineFormat(_ language: GameLanguage) -> TimelineFormat {
    TimelineFormat(language: language, timeZone: timeZone, hourCycle: hourCycle)
  }
}
#endif
