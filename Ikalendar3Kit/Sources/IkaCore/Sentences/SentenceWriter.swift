//
//  SentenceWriter.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - SentenceWriter

/// Writes the one sentence a Rotation or a Shift reads as, in one of the 14 text sets. VoiceOver
/// reads it on every Surface and Siri's answers are built from it, so every Surface reads alike.
///
/// Names come from the game's terms in their text set. Times are written in the time zone and
/// the hour cycle passed in; Surfaces pass the device's own (`Locale.current.hourCycle`), so a
/// sentence reads times as the device shows them.
public struct SentenceWriter: Sendable {
  /// The game's names, which also fix the text set.
  public let terms: GameTerms
  /// The time zone times are written in.
  public let timeZone: TimeZone
  /// Whether times read on a 12- or a 24-hour clock.
  public let hourCycle: Locale.HourCycle

  public init(terms: GameTerms, timeZone: TimeZone, hourCycle: Locale.HourCycle) {
    self.terms = terms
    self.timeZone = timeZone
    self.hourCycle = hourCycle
  }

  /// A Rotation's sentence: its Battle Mode, Rule, both Stages and time range, plus the time
  /// left while it runs at `instant`. A paused Rotation reads that the Splatfest pauses it.
  ///
  /// A Rotation lasts hours, so its times carry no day.
  public func sentence(for rotation: Rotation, at instant: Date) -> String {
    let when = when(rotation, at: instant, times: .init().hour().minute())
    guard let setting = rotation.setting else {
      return format("sentence.rotation.paused", mode(rotation.mode), when)
    }

    return format(
      "sentence.rotation",
      mode(rotation.mode),
      terms.name(of: setting.rule),
      list(setting.stages.map(terms.name(of:))),
      when)
  }

  /// A Shift's sentence: Salmon Run, Big Run or Eggstra Work, its Stage, four weapons and time
  /// range, plus the time left while it runs at `instant`. The golden random mark reads as
  /// rare random.
  ///
  /// A Shift spans days, so its times carry the weekday.
  public func sentence(for shift: Shift, at instant: Date) -> String {
    let kind: ModeLabel =
      switch shift.kind {
        case .regular: .salmonRun
        case .bigRun: .bigRun
        case .eggstraWork: .eggstraWork
      }
    return format(
      "sentence.shift",
      kind.text(in: language),
      terms.name(of: shift.stage),
      list(shift.weapons.map(weaponName)),
      when(shift, at: instant, times: .init().weekday(.wide).hour().minute()))
  }

  /// The time left in a window, which is how a progress bar or ring reads: whole hours and
  /// minutes, rounded up to the minute so a running window never reads zero.
  public func timeLeft(_ progress: WindowProgress) -> String {
    let minutes: Int = .init((progress.timeLeft / .seconds(60)).rounded(.up))
    let (hours, minutesPastHour) = minutes.quotientAndRemainder(dividingBy: 60)
    let span =
      switch (hours, minutesPastHour) {
        case (0, _): TimeUnit.minutes.spelledOut(minutesPastHour, in: language)
        case (_, 0): TimeUnit.hours.spelledOut(hours, in: language)
        default:
          format(
            "sentence.hoursAndMinutes",
            TimeUnit.hours.spelledOut(hours, in: language),
            TimeUnit.minutes.spelledOut(minutesPastHour, in: language))
      }
    return format("sentence.timeLeft", span)
  }

  // MARK: Parts

  /// The time range of a window with its times in `style`, plus the time left while it runs at
  /// `instant`.
  private func when(_ window: some TimeWindow, at instant: Date, times style: Date.FormatStyle) -> String {
    var style = style.locale(locale)
    style.timeZone = timeZone
    let range = format("sentence.timeRange", window.startTime.formatted(style), window.endTime.formatted(style))
    guard window.isRunning(at: instant) else { return range }

    return format("sentence.timeRangeAndTimeLeft", range, timeLeft(window.progress(at: instant)))
  }

  /// A weapon's name; the golden random mark, which the game names like the green one, reads
  /// as rare random.
  private func weaponName(_ id: WeaponID) -> String {
    id == .rareRandom ? format("weapon.rareRandom", terms.name(of: id)) : terms.name(of: id)
  }

  /// A Rotation's Battle Mode name, with its form for Anarchy Battle and Splatfest Battle.
  private func mode(_ mode: RotationMode) -> String {
    switch mode {
      case .battle(.regular): ModeLabel.regularBattle.text(in: language)
      case .battle(.anarchySeries): withForm(.anarchyBattle, .series)
      case .battle(.anarchyOpen): withForm(.anarchyBattle, .open)
      case .battle(.x): ModeLabel.xBattle.text(in: language)
      case .splatfestBattle(.open): withForm(.splatfestBattle, .open)
      case .splatfestBattle(.pro): withForm(.splatfestBattle, .pro)
    }
  }

  private func withForm(_ mode: ModeLabel, _ form: ModeLabel) -> String {
    format("sentence.modeWithForm", mode.text(in: language), form.text(in: language))
  }

  /// Names joined as the text set lists them: "A and B", "A、B".
  private func list(_ names: [String]) -> String {
    names.formatted(.list(type: .and).locale(locale))
  }

  /// A catalog template in the text set, filled in.
  private func format(_ key: String, _ arguments: any CVarArg...) -> String {
    String(format: Bundle.module.localizedString(forKey: key, in: language), locale: locale, arguments: arguments)
  }

  private var language: GameLanguage { terms.language }

  /// The text set's locale on the hour cycle passed in.
  private var locale: Locale {
    var components = Locale.Components(identifier: language.rawValue)
    components.hourCycle = hourCycle
    return Locale(components: components)
  }
}
