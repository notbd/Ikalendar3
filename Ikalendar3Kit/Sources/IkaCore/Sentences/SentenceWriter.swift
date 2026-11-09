//
//  SentenceWriter.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - SentenceWriter

/// Writes the one sentence a Rotation, a Shift, a Challenge window or a Splatfest reads as, in one
/// of the 14 text sets. VoiceOver reads it on every Surface and Siri's answers are built from it,
/// so every Surface reads alike.
///
/// Names come from the game's terms in their text set. Times are written in the time zone and
/// the hour cycle passed in; Surfaces pass the device's own (views through `IkaDesign`'s
/// `TimeSettings`), so a sentence reads times as the device shows them.
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
  /// A Rotation lasts hours, so its times carry no day, except that a Rotation not on at
  /// `instant` that starts on another day reads its start's weekday ("from Tuesday 3:00 AM to
  /// 5:00 AM"): a spoken answer has no list around it to tell that 3:00 AM is tomorrow's.
  ///
  /// Only Rotations that play reach it: IkaCore builds every Rotation, hands out only those that
  /// play, and reads a pause with `sentence(forPauseOf:returningAt:)` and the Battle Mode's
  /// return time. The fallback for a paused window, paused until the window's end, is therefore
  /// never read.
  public func sentence(for rotation: Rotation, at instant: Date) -> String {
    sentence(of: rotation.mode.name(in: language), playing: rotation.setting, in: rotation, at: instant)
  }

  /// A Rotation's sentence with no time left and no day: its Battle Mode, Rule, both Stages and
  /// time range. Widgets read it, because the system draws them ahead of the moment VoiceOver reads
  /// them, when a time left would be wrong; their countdown is the system's timer text, and their
  /// layout fixes the day.
  public func sentence(for rotation: Rotation) -> String {
    sentence(of: rotation.mode.name(in: language), playing: rotation.setting, in: rotation, at: nil)
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
    sentence(of: shift, at: instant)
  }

  /// A Shift's sentence with no time left: Salmon Run, Big Run or Eggstra Work, its Stage, four
  /// weapons and time range. The Salmon Run widget reads it, as the battle widgets read
  /// `sentence(for:)` of a Rotation.
  public func sentence(for shift: Shift) -> String {
    sentence(of: shift, at: nil)
  }

  /// A Tracking item's sentence: the regular Shift or Big Run it stands for, read as
  /// `sentence(for:at:)`.
  public func sentence(for item: TrackedShift, at instant: Date) -> String {
    sentence(of: item.isBigRun ? .bigRun : .salmonRun, on: item.stage, with: item.weapons, in: item, at: instant)
  }

  /// A Challenge window's sentence: a Rotation's, with the Challenge's name in the Battle Mode's
  /// place, plus the time left while the window runs at `instant`.
  ///
  /// A Challenge window lasts hours, so its times read as a Rotation's do: its start carries the
  /// weekday only when the window is not on at `instant` and starts on another day.
  public func sentence(for window: ChallengeWindow, at instant: Date) -> String {
    let challenge = window.challenge
    return format(
      "sentence.rotation",
      terms.challenge(challenge.id).name,
      terms.name(of: challenge.rule),
      list(challenge.stages.map(terms.name(of:))),
      hoursLongWhen(window, at: instant))
  }

  /// Tricolor Turf War's sentence: a Rotation's, with Splatfest Battle as the Battle Mode and
  /// Tricolor in the Rule's place, plus the time left while it runs at `instant`.
  ///
  /// It runs through the Splatfest's second half, a day long, so its times carry the weekday.
  public func sentence(for tricolorTurfWar: TricolorTurfWar, at instant: Date) -> String {
    format(
      "sentence.rotation",
      ModeLabel.splatfestBattle.text(in: language),
      ModeLabel.tricolor.text(in: language),
      list(tricolorTurfWar.stages.map(terms.name(of:))),
      when(tricolorTurfWar, at: instant, times: Self.weekdayAndTimeStyle))
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

  /// An event card's sentence: the sentence of the Challenge window, Splatfest or Shift it shows.
  public func sentence(for event: EventItem, at instant: Date) -> String {
    switch event {
      case .challenge(let window): sentence(for: window, at: instant)
      case .splatfest(let splatfest): sentence(for: splatfest, at: instant)
      case .bigRun(let shift),
           .eggstraWork(let shift): sentence(for: shift, at: instant)
    }
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

  /// The time left in a window as a ticking countdown shows it: abbreviated units from the
  /// largest one that is not zero down to whole seconds, rounded up so a running window never
  /// reads zero. Hours run past a day, as `timeLeft(_:)` reads them.
  public func countdown(_ progress: WindowProgress) -> String {
    let seconds: Int = .init((progress.timeLeft / .seconds(1)).rounded(.up))
    let (hours, secondsPastHour) = seconds.quotientAndRemainder(dividingBy: 3600)
    let (minutes, secondsPastMinute) = secondsPastHour.quotientAndRemainder(dividingBy: 60)
    let parts: [(unit: TimeUnit, amount: Int)] = [(.hours, hours), (.minutes, minutes), (.seconds, secondsPastMinute)]
    let span = parts
      .drop { $0.amount == 0 && $0.unit != .seconds }
      .lazy
      .map { $0.unit.abbreviated($0.amount, in: language) }
      .reduce(nil) { span, part in span.map { format("sentence.hoursAndMinutes", $0, part) } ?? part }
    return format("sentence.timeLeft", span ?? "")
  }

  /// The pause sentence of a Battle Mode named `mode`. `SiriAnswers` reads a lineup's pause
  /// with it.
  func pauseSentence(named mode: String, returningAt returnTime: Date) -> String {
    format("sentence.pause", mode, returnTime.formatted(localized(Self.weekdayAndTimeStyle)))
  }

  // MARK: Parts

  /// The sentence of a Rotation of Battle Mode `mode` over `window`, or of its pause until the
  /// window ends when `setting` is `nil`. With no `instant`, it reads no time left and no day.
  private func sentence(
    of mode: String,
    playing setting: Rotation.Setting?,
    in window: some TimeWindow,
    at instant: Date?)
    -> String
  {
    guard let setting else { return pauseSentence(named: mode, returningAt: window.endTime) }

    return format(
      "sentence.rotation",
      mode,
      terms.name(of: setting.rule),
      list(setting.stages.map(terms.name(of:))),
      hoursLongWhen(window, at: instant))
  }

  /// A Shift's sentence. With no `instant`, it reads no time left.
  private func sentence(of shift: Shift, at instant: Date?) -> String {
    sentence(of: ModeLabel(shift.kind), on: shift.stage, with: shift.weapons, in: shift, at: instant)
  }

  /// The sentence of a Shift of `kind` over `window`. With no `instant`, it reads no time left.
  private func sentence(
    of kind: ModeLabel,
    on stage: StageID,
    with weapons: [WeaponID],
    in window: some TimeWindow,
    at instant: Date?)
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

  /// The time range of a window hours long, a Rotation's or a Challenge window's, plus the time
  /// left while it runs at `instant`: times only, except that a window not on at `instant` that
  /// starts on another day reads its start's weekday. With no `instant`, no time left and no day.
  private func hoursLongWhen(_ window: some TimeWindow, at instant: Date?) -> String {
    let time: Date.FormatStyle = .init().hour().minute()
    let startsOnAnotherDay = instant.map { !window.isRunning(at: $0) && !isSameDay(window.startTime, $0) } ?? false
    return when(window, at: instant, times: time, startTime: startsOnAnotherDay ? Self.weekdayAndTimeStyle : time)
  }

  /// The time range of a window with its times in `style`, its start in `startStyle` if one is
  /// given, plus the time left while it runs at `instant`, if one is given.
  private func when(
    _ window: some TimeWindow,
    at instant: Date?,
    times style: Date.FormatStyle,
    startTime startStyle: Date.FormatStyle? = nil)
    -> String
  {
    let range = format(
      "sentence.timeRange",
      window.startTime.formatted(localized(startStyle ?? style)),
      window.endTime.formatted(localized(style)))
    guard let instant, window.isRunning(at: instant) else { return range }

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

  /// Whether two instants fall on one day in the time zone.
  private func isSameDay(_ first: Date, _ second: Date) -> Bool {
    var calendar: Calendar = .init(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar.isDate(first, inSameDayAs: second)
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
