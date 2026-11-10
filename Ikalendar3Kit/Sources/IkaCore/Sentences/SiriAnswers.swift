//
//  SiriAnswers.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - SiriAnswers

/// What Siri says for the five question shortcuts, from the cached snapshot. An item is read in
/// `SentenceWriter`'s sentence, the one VoiceOver reads, so Siri and every Surface agree.
///
/// Siri never makes an answer up. When the cache holds no answer it says why:
/// - The published Schedule does not reach that far: the next item or the Rule asked for is
///   not published yet.
/// - None is announced: the feed names no Big Run or Splatfest to come.
/// - The Schedule is out of date: the cached Schedule ran out or failed to decode, or nothing
///   is cached yet, so the cache cannot tell.
///
/// While a Splatfest pauses a Battle Mode, the now answer says when the Battle Mode comes back,
/// as the iPhone tabs do. The next and Rule answers do so from the last Rotation before the
/// Splatfest on, since the feed publishes the paused windows: a Rotation after the Splatfest
/// follows that pause sentence; with none published yet, the pause sentence is the answer.
///
/// A Rotation that starts on another day than the question reads its start's weekday, as
/// `SentenceWriter.sentence(for:at:)` writes it.
public struct SiriAnswers: Sendable {
  private let snapshot: Snapshot
  private let writer: SentenceWriter

  /// The answers over `snapshot`, in a text set, with times in a time zone and hour cycle.
  public init(snapshot: Snapshot, language: GameLanguage, timeZone: TimeZone, hourCycle: Locale.HourCycle) {
    self.snapshot = snapshot
    writer = SentenceWriter(terms: snapshot.terms(in: language), timeZone: timeZone, hourCycle: hourCycle)
  }

  /// What is on now in a Mode: its Rotation or Shift with the time left.
  public func now(in mode: Mode, at instant: Date) -> String {
    switch mode {
      case .battle(let battleMode):
        now(in: mode, battleLineup(battleMode, at: instant)) { writer.sentence(for: $0, at: instant) }
      case .salmonRun:
        now(in: mode, feed.salmonRunLineup(at: instant)) { writer.sentence(for: $0, at: instant) }
    }
  }

  /// What comes next in a Mode: the Rotation or Shift after the one on now.
  public func next(in mode: Mode, at instant: Date) -> String {
    switch mode {
      case .battle(let battleMode):
        let lineup = battleLineup(battleMode, at: instant)
        guard let returnTime = returnTime(ahead: lineup, of: battleMode) else {
          return next(in: mode, lineup) { writer.sentence(for: $0, at: instant) }
        }

        return sentence(forPauseOf: battleMode, returningAt: returnTime, then: lineup.next, at: instant)

      case .salmonRun:
        return next(in: mode, feed.salmonRunLineup(at: instant)) { writer.sentence(for: $0, at: instant) }
    }
  }

  /// When a Rule next comes up in a Battle Mode: the first published Rotation from the one on
  /// now on that plays it, with the time left when it is on now. A Rule no published Rotation
  /// plays is not published, unless a pause ahead leaves nothing after it published yet.
  public func next(_ rule: RuleID, in battleMode: BattleMode, at instant: Date) -> String {
    let lineup = battleLineup(battleMode, at: instant)
    let returnTime = returnTime(ahead: lineup, of: battleMode)
    if let rotation = lineup.items.first(where: { $0.setting?.rule == rule }) {
      guard let returnTime, returnTime <= rotation.startTime else { return writer.sentence(for: rotation, at: instant) }

      return sentence(forPauseOf: battleMode, returningAt: returnTime, then: rotation, at: instant)
    }
    if let returnTime, lineup.next == nil {
      return writer.sentence(forPauseOf: battleMode, returningAt: returnTime)
    }

    let mode = Mode.battle(battleMode).name(in: language)
    return lineup.current == .ranOut
      ? writer.format("answer.outOfDate", mode)
      : writer.format("answer.notPublished.rule", mode, writer.terms.name(of: rule))
  }

  /// The Shift on now: the regular Shift or Big Run, never an Eggstra Work, which runs beside
  /// it. The same answer as now in Salmon Run.
  public func currentShift(at instant: Date) -> String {
    now(in: .salmonRun, at: instant)
  }

  /// When the next Big Run and the next Splatfest are, one sentence each; one on now reads its
  /// time left.
  public func nextBigRunAndSplatfest(at instant: Date) -> String {
    writer.format("answer.twoSentences", nextBigRun(at: instant), nextSplatfest(at: instant))
  }

  // MARK: Parts

  private func now<Item>(in mode: Mode, _ lineup: Lineup<Item>, sentence: (Item) -> String) -> String {
    let name = mode.name(in: language)
    return switch lineup.current {
      case .item(let item): sentence(item)
      case .paused(let returnTime): writer.pauseSentence(named: name, returningAt: returnTime)
      case .ranOut: writer.format("answer.outOfDate", name)
      case .gap,
           .noneAnnounced: writer.format("answer.notPublished.now", name)
    }
  }

  private func next<Item>(in mode: Mode, _ lineup: Lineup<Item>, sentence: (Item) -> String) -> String {
    if let next = lineup.next { return sentence(next) }

    let name = mode.name(in: language)
    return switch lineup.current {
      case .paused(let returnTime): writer.pauseSentence(named: name, returningAt: returnTime)
      case .ranOut: writer.format("answer.outOfDate", name)
      case .item,
           .gap,
           .noneAnnounced: writer.format("answer.notPublished.next", name)
    }
  }

  /// When the Splatfest pause a Battle Mode is in, or enters as its Rotation on now ends, gives
  /// it back; `nil` when no pause comes before its next Rotation.
  private func returnTime(ahead lineup: Lineup<Rotation>, of battleMode: BattleMode) -> Date? {
    var current = lineup.current
    if case .item(let rotation) = current {
      current = battleLineup(battleMode, at: rotation.endTime).current
    }
    return if case .paused(let returnTime) = current { returnTime } else { nil }
  }

  /// The pause sentence, then the sentence of `rotation`, a Rotation after the pause, when there
  /// is one.
  private func sentence(
    forPauseOf battleMode: BattleMode,
    returningAt returnTime: Date,
    then rotation: Rotation?,
    at instant: Date)
    -> String
  {
    let pause = writer.sentence(forPauseOf: battleMode, returningAt: returnTime)
    guard let rotation else { return pause }

    return writer.format("answer.twoSentences", pause, writer.sentence(for: rotation, at: instant))
  }

  /// The Big Run on now or the next one Salmon Run's Schedule holds.
  private func nextBigRun(at instant: Date) -> String {
    let lineup = feed.salmonRunLineup(at: instant)
    if let bigRun = lineup.items.first(where: { $0.kind == .bigRun }) {
      return writer.sentence(for: bigRun, at: instant)
    }

    let name = ModeLabel.bigRun.text(in: language)
    return lineup.current == .ranOut
      ? writer.format("answer.outOfDate", name)
      : writer.format("answer.noneAnnounced", name)
  }

  /// The Splatfest running or announced. With none, the feed must still be current to say
  /// none is announced: its Splatfest decoded and a continuous Battle Mode not run out.
  private func nextSplatfest(at instant: Date) -> String {
    if let splatfest = snapshot.splatfest, instant < splatfest.endTime {
      return writer.sentence(for: splatfest, at: instant)
    }

    let name = ModeLabel.splatfest.text(in: language)
    let isOutOfDate = feed.failedSections.contains(.splatfest)
      || BattleMode.allCases.allSatisfy { battleLineup($0, at: instant).current == .ranOut }
    return isOutOfDate
      ? writer.format("answer.outOfDate", name)
      : writer.format("answer.noneAnnounced", name)
  }

  private func battleLineup(_ battleMode: BattleMode, at instant: Date) -> Lineup<Rotation> {
    feed.battleLineup(of: .battle(battleMode), at: instant)
  }

  /// The cached schedules feed; before its first good response, an empty one, whose
  /// continuous Schedules have run out.
  private var feed: ScheduleFeed { snapshot.schedules?.content ?? .empty }

  private var language: GameLanguage { writer.terms.language }
}

// MARK: - Lineup

extension Lineup {
  /// Every published item from the one on now on, in time order.
  fileprivate var items: [Item] {
    [current.item, next].compactMap(\.self) + later
  }
}

// MARK: - ScheduleFeed

extension ScheduleFeed {
  /// A feed with nothing published, standing in before the first good response.
  static fileprivate let empty: ScheduleFeed = .init(
    rotationsByMode: [:],
    challenges: [],
    salmonRun: [],
    eggstraWork: [],
    currentSplatfest: nil,
    terms: TermTable(),
    failedSections: [])
}
