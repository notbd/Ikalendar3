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

/// How Timeline writes times, as SplatNet 3's schedule page does: on a 24-hour clock whatever the
/// device's hour cycle, in the app language and the player's time zone.
struct TimelineFormat {
  /// The app language.
  let language: GameLanguage
  /// The time zone times are written in.
  let timeZone: TimeZone

  /// A start time's pin on the axis: "08:00".
  func pin(_ instant: Date) -> String {
    instant.formatted(style(.init().hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))
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

  /// A Shift's start and end with their weekdays, joined as the game joins a range:
  /// "Tue 17:00 - Thu 09:00".
  func timeRange(from start: Date, to end: Date) -> String {
    let style: Date.FormatStyle = style(.init().weekday(.abbreviated).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    return TimelineText.timeRange.text(in: language, start.formatted(style), end.formatted(style))
  }

  /// The time left as a countdown on whole seconds, rounded up so a running window never reads
  /// zero, its hours running past a day: "1:09:59".
  static func countdown(_ timeLeft: Duration) -> String {
    let seconds: Int = .init((timeLeft / .seconds(1)).rounded(.up))
    let (hours, secondsPastHour) = seconds.quotientAndRemainder(dividingBy: 3600)
    let (minutes, secondsPastMinute) = secondsPastHour.quotientAndRemainder(dividingBy: 60)
    return "\(hours):\(twoDigits(minutes)):\(twoDigits(secondsPastMinute))"
  }

  /// `value` with a leading zero below 10.
  private static func twoDigits(_ value: Int) -> String {
    value < 10 ? "0\(value)" : "\(value)"
  }

  /// `style` in the app language on a 24-hour clock and in the time zone.
  private func style(_ style: Date.FormatStyle) -> Date.FormatStyle {
    var components: Locale.Components = .init(identifier: language.rawValue)
    components.hourCycle = .zeroToTwentyThree
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
#endif
