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
  /// left while it runs at `instant`.
  ///
  /// A Rotation lasts hours, so its times carry no day.
  ///
  /// A lineup's Rotations always play: a paused window is never an item, and a pause reads
  /// `sentence(forPauseOf:returningAt:)` with the lineup's return time. A paused window taken
  /// straight from the feed knows only its own end, so it reads as paused until then.
  public func sentence(for rotation: Rotation, at instant: Date) -> String {
    sentence(of: rotation.mode.name(in: language), playing: rotation.setting, in: rotation, at: instant)
  }

  /// A Tracking item's sentence: a Rotation of `mode` reads as `sentence(for:at:)`, a pause as
  /// `sentence(forPauseOf:returningAt:)` with the item's end, when the Battle Mode returns.
  public func sentence(for item: TrackedRotation, of mode: BattleMode, at instant: Date) -> String {
    sentence(of: mode.name(in: language), playing: item.setting, in: item, at: instant)
  }

  /// The sentence of a Battle Mode a Splatfest pauses: the Battle Mode and when it comes back,
  /// as `OnNow.paused(returnTime:)` and a lineup's pause carry it.
  ///
  /// The return can be days away, so its time carries the weekday.
  public func sentence(forPauseOf mode: BattleMode, returningAt returnTime: Date) -> String {
    pauseSentence(named: mode.name(in: language), returningAt: returnTime)
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
    return sentence(of: kind, on: shift.stage, with: shift.weapons, in: shift, at: instant)
  }

  /// A Tracking item's sentence: the regular Shift or Big Run it stands for, read as
  /// `sentence(for:at:)`.
  public func sentence(for item: TrackedShift, at instant: Date) -> String {
    sentence(of: item.isBigRun ? .bigRun : .salmonRun, on: item.stage, with: item.weapons, in: item, at: instant)
  }

  /// A Splatfest's sentence: its title and time range, plus the time left while it runs at
  /// `instant`.
  ///
  /// A Splatfest is announced up to weeks ahead, so its times carry the date.
  public func sentence(for splatfest: Splatfest, at instant: Date) -> String {
    format(
      "sentence.splatfest",
      ModeLabel.splatfest.text(in: language),
      terms.splatfest(splatfest.id).title,
      when(splatfest, at: instant, times: .init().weekday(.wide).month(.wide).day().hour().minute()))
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

  /// The pause sentence of a Battle Mode named `mode`. `SiriAnswers` reads a lineup's pause
  /// with it.
  func pauseSentence(named mode: String, returningAt returnTime: Date) -> String {
    format("sentence.pause", mode, returnTime.formatted(localized(Self.weekdayAndTimeStyle)))
  }

  // MARK: Parts

  /// The sentence of a Rotation of Battle Mode `mode` over `window`, or of its pause until the
  /// window ends when `setting` is `nil`.
  private func sentence(
    of mode: String,
    playing setting: Rotation.Setting?,
    in window: some TimeWindow,
    at instant: Date)
    -> String
  {
    guard let setting else { return pauseSentence(named: mode, returningAt: window.endTime) }

    return format(
      "sentence.rotation",
      mode,
      terms.name(of: setting.rule),
      list(setting.stages.map(terms.name(of:))),
      when(window, at: instant, times: .init().hour().minute()))
  }

  /// The sentence of a Shift of `kind` over `window`.
  private func sentence(
    of kind: ModeLabel,
    on stage: StageID,
    with weapons: [WeaponID],
    in window: some TimeWindow,
    at instant: Date)
    -> String
  {
    format(
      "sentence.shift",
      kind.text(in: language),
      terms.name(of: stage),
      list(weapons.map(weaponName)),
      when(window, at: instant, times: Self.weekdayAndTimeStyle))
  }

  /// A weekday and a time: "Thursday 8:00 AM".
  static private let weekdayAndTimeStyle: Date.FormatStyle = .init().weekday(.wide).hour().minute()

  /// The time range of a window with its times in `style`, plus the time left while it runs at
  /// `instant`.
  private func when(_ window: some TimeWindow, at instant: Date, times style: Date.FormatStyle) -> String {
    let style = localized(style)
    let range = format("sentence.timeRange", window.startTime.formatted(style), window.endTime.formatted(style))
    guard window.isRunning(at: instant) else { return range }

    return format("sentence.timeRangeAndTimeLeft", range, timeLeft(window.progress(at: instant)))
  }

  /// A weapon's name; the golden random mark, which the game names like the green one, reads
  /// as rare random.
  private func weaponName(_ id: WeaponID) -> String {
    id == .rareRandom ? format("weapon.rareRandom", terms.name(of: id)) : terms.name(of: id)
  }

  /// Names joined as the text set lists them: "A and B", "A、B".
  private func list(_ names: [String]) -> String {
    names.formatted(.list(type: .and).locale(locale))
  }

  /// A format style in the text set, time zone and hour cycle.
  private func localized(_ style: Date.FormatStyle) -> Date.FormatStyle {
    var style = style.locale(locale)
    style.timeZone = timeZone
    return style
  }

  /// A catalog template in the text set, filled in. `SiriAnswers` writes its own templates
  /// with it.
  ///
  /// A sentence whose last time ends in an abbreviation ("4:00 p. m.") ends on that period,
  /// not on a second one.
  func format(_ key: String, _ arguments: any CVarArg...) -> String {
    let text: String = .init(
      format: Bundle.module.localizedString(forKey: key, in: language),
      locale: locale,
      arguments: arguments)
    return text.hasSuffix("..") ? String(text.dropLast()) : text
  }

  private var language: GameLanguage { terms.language }

  /// The text set's locale on the hour cycle passed in.
  private var locale: Locale {
    var components = Locale.Components(identifier: language.rawValue)
    components.hourCycle = hourCycle
    return Locale(components: components)
  }
}
