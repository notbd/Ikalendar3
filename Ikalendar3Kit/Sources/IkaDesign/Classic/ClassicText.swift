//
//  ClassicText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import Foundation
import IkaCore

// MARK: - ClassicText

/// Classic's own strings, from `IkaDesign`'s `Classic` string table: ikalendar 2's tags,
/// countdowns and day words. The raw value is the catalog key.
enum ClassicText: String, CaseIterable {
  /// "Now:", on the featured place of a Battle Mode.
  case now = "classic.tag.now"
  /// "Next:", on the next Rotation or Shift.
  case next = "classic.tag.next"
  /// "Open!", on a running Shift.
  case open = "classic.tag.open"
  /// "Soon:", on the first Shift when none runs.
  case soon = "classic.tag.soon"
  /// "%@ remaining", with a countdown.
  case timeLeft = "classic.timeLeft"
  /// "in %@", with a countdown to a start.
  case timeUntil = "classic.timeUntil"
  /// "Today", before a time.
  case today = "classic.day.today"
  /// "Tomorrow", before a time.
  case tomorrow = "classic.day.tomorrow"
  /// "Yesterday", before a time.
  case yesterday = "classic.day.yesterday"

  /// The string in a text set, its placeholders filled in.
  func text(in language: GameLanguage, _ arguments: any CVarArg...) -> String {
    let template = Bundle.module.localizedString(forKey: rawValue, table: "Classic", in: language)
    return arguments.isEmpty
      ? template
      : String(format: template, locale: Locale(identifier: language.rawValue), arguments: arguments)
  }
}

// MARK: - ClassicTimeFormat

/// How Classic writes times, as ikalendar 2 did: a Rotation's range with a day word only where it
/// leaves today, each end of a Shift with its day, and countdowns down to the second. Times are in
/// the app language's locale on the device's hour cycle and in the player's time zone; views take
/// it from `TimeSettings`.
struct ClassicTimeFormat {
  /// The app language.
  let language: GameLanguage
  /// The time zone times are written in.
  let timeZone: TimeZone
  /// Whether times read on a 12- or a 24-hour clock.
  let hourCycle: Locale.HourCycle

  /// A Rotation's range, "22:00 - Tomorrow 00:00": the start carries its day when it is not
  /// today, the end when it is a day after the start and the start is not marked yet.
  func battleRange(from start: Date, to end: Date, now: Date) -> String {
    let startDay: Int = dayOffset(of: start, from: now)
    let endDay: Int = dayOffset(of: end, from: now)
    let startText: String = startDay == 0 ? time(start) : dayed(start, offset: startDay)
    let endText: String = endDay != startDay ? dayed(end, offset: endDay) : time(end)
    return "\(startText) - \(endText)"
  }

  /// One end of a Shift with its day: "Today 16:00" near now, "Thu, 10/22, 08:00" further away.
  func shiftTime(_ instant: Date, now: Date) -> String {
    dayed(instant, offset: dayOffset(of: instant, from: now))
  }

  /// A countdown, "1d 12h 5m 9s": the `Countdown` every Style shows, its hours split into days,
  /// every unit that is not empty and the seconds always.
  func span(_ duration: Duration) -> String {
    let countdown: Countdown = .init(duration)
    let units: [(TimeUnit, Int)] = [
      (.days, countdown.hours / 24),
      (.hours, countdown.hours % 24),
      (.minutes, countdown.minutes),
    ]
    let parts: [String] = units.filter { $0.1 > 0 }.map { $0.0.abbreviated($0.1, in: language) }
      + [TimeUnit.seconds.abbreviated(countdown.seconds, in: language)]
    return parts.joined(separator: unitSeparator)
  }

  // MARK: Parts

  /// `instant` after its day word, or with its date when it is not within a day of now.
  private func dayed(_ instant: Date, offset: Int) -> String {
    let word: ClassicText? =
      switch offset {
        case -1: .yesterday
        case 0: .today
        case 1: .tomorrow
        default: nil
      }
    guard let word else { return instant.formatted(style.weekday(.abbreviated).month(.defaultDigits).day()) }

    return "\(word.text(in: language)) \(time(instant))"
  }

  /// `instant`'s time of day.
  private func time(_ instant: Date) -> String {
    instant.formatted(style)
  }

  /// How many days `instant` falls after `now`'s day: -1 for yesterday, 1 for tomorrow.
  private func dayOffset(of instant: Date, from now: Date) -> Int {
    calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: instant)).day ?? 0
  }

  /// Japanese and Chinese write a span's units together; the others space them.
  private var unitSeparator: String {
    switch language {
      case .jaJP,
           .zhCN,
           .zhTW: ""
      case .enUS,
           .enGB,
           .esES,
           .esMX,
           .frFR,
           .frCA,
           .deDE,
           .itIT,
           .nlNL,
           .ruRU,
           .koKR: " "
    }
  }

  /// Hours and minutes in the language's locale on the hour cycle, in the time zone.
  private var style: Date.FormatStyle {
    var components: Locale.Components = .init(identifier: language.rawValue)
    components.hourCycle = hourCycle
    return Date.FormatStyle(locale: Locale(components: components), calendar: calendar, timeZone: timeZone)
      .hour()
      .minute()
  }

  private var calendar: Calendar {
    var calendar: Calendar = .init(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
  }
}

extension TimeSettings {
  /// How Classic writes times in `language`.
  func classicFormat(_ language: GameLanguage) -> ClassicTimeFormat {
    ClassicTimeFormat(language: language, timeZone: timeZone, hourCycle: hourCycle)
  }
}
#endif
