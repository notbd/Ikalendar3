//
//  QuestionIntents.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import AppIntents
import Foundation
import IkaCore
import OSLog

// MARK: - QuestionIntent

/// A Siri question: an intent whose answer is one of `SiriAnswers`'. Each one's `perform` asks
/// `AnswerSource.forIntents()` and returns the answer as Siri's dialog and as the action's output
/// in Shortcuts.
public protocol QuestionIntent: AppIntent {
  /// The answer this question picks among `answers` at `instant`.
  func answer(from answers: SiriAnswers, at instant: Date) -> String
}

// MARK: - AnswerSource

/// Where a question intent's answer comes from: a run of the effects shell, so a fetch Siri
/// triggers also reloads widgets, rebuilds reminders and re-arms Tracking, then `SiriAnswers` over
/// the snapshot the run left, in a text set and the time settings, at the moment the run ends.
@MainActor
public struct AnswerSource {
  private let shell: EffectsShell
  private let language: GameLanguage
  private let timeZone: TimeZone
  private let hourCycle: Locale.HourCycle
  private let clock: any TimeSource

  /// Answers after a run of `shell`, in `language`, with times in a time zone and hour cycle, at
  /// the instant `clock` shows as the run ends.
  public init(
    shell: EffectsShell,
    language: GameLanguage,
    timeZone: TimeZone,
    hourCycle: Locale.HourCycle,
    clock: any TimeSource = SystemTimeSource())
  {
    self.shell = shell
    self.language = language
    self.timeZone = timeZone
    self.hourCycle = hourCycle
    self.clock = clock
  }

  /// The source an intent asks: `EffectsShell.forIntents()`, in the app language and the
  /// device's time zone and hour cycle.
  ///
  /// - Throws: `TrackingError.noSchedule` with no App Group container.
  static func forIntents() throws -> AnswerSource {
    try AnswerSource(
      shell: .forIntents(),
      language: GameLanguage(resolvedFor: .main),
      timeZone: .current,
      hourCycle: Locale.current.hourCycle)
  }

  /// Logs which process runs `question`, refreshes under the hourly gate and answers it at the
  /// instant the refresh ends: a refresh that crosses a Rotation boundary answers with the
  /// Rotation it ends in.
  public func answer<Question: QuestionIntent>(_ question: Question) async -> String {
    Logger.logRun(of: Question.self)
    let result = await shell.run()
    let answers: SiriAnswers = .init(
      snapshot: result.snapshot,
      language: language,
      timeZone: timeZone,
      hourCycle: hourCycle)
    return question.answer(from: answers, at: clock.now)
  }

  /// `question`'s answer as Siri says it and Shortcuts passes it on.
  func result(of question: some QuestionIntent) async -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let answer = await answer(question)
    return .result(value: answer, dialog: IntentDialog(stringLiteral: answer))
  }
}

// MARK: - NowIntent

/// What is on now in a Mode.
public struct NowIntent: QuestionIntent {
  static public let title: LocalizedStringResource = .init("What's On Now", bundle: #bundle)

  @Parameter(title: LocalizedStringResource("Mode", bundle: #bundle))
  public var mode: ModeParameter

  public init() { }

  public init(mode: ModeParameter) {
    self.mode = mode
  }

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    try await AnswerSource.forIntents().result(of: self)
  }

  public func answer(from answers: SiriAnswers, at instant: Date) -> String {
    answers.now(in: mode.mode, at: instant)
  }
}

// MARK: - NextIntent

/// What comes next in a Mode.
public struct NextIntent: QuestionIntent {
  static public let title: LocalizedStringResource = .init("What's Next", bundle: #bundle)

  @Parameter(title: LocalizedStringResource("Mode", bundle: #bundle))
  public var mode: ModeParameter

  public init() { }

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    try await AnswerSource.forIntents().result(of: self)
  }

  public func answer(from answers: SiriAnswers, at instant: Date) -> String {
    answers.next(in: mode.mode, at: instant)
  }
}

// MARK: - NextRuleIntent

/// When a Rule next comes up in a Battle Mode.
public struct NextRuleIntent: QuestionIntent {
  static public let title: LocalizedStringResource = .init("When a Rule Is Next", bundle: #bundle)

  @Parameter(title: LocalizedStringResource("Rule", bundle: #bundle))
  public var rule: RuleParameter

  @Parameter(title: LocalizedStringResource("Battle Mode", bundle: #bundle))
  public var battleMode: BattleModeParameter

  public init() { }

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    try await AnswerSource.forIntents().result(of: self)
  }

  public func answer(from answers: SiriAnswers, at instant: Date) -> String {
    answers.next(rule.rule, in: battleMode.battleMode, at: instant)
  }
}

// MARK: - CurrentShiftIntent

/// The Salmon Run Shift on now.
public struct CurrentShiftIntent: QuestionIntent {
  static public let title: LocalizedStringResource = .init("Current Shift", bundle: #bundle)

  public init() { }

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    try await AnswerSource.forIntents().result(of: self)
  }

  public func answer(from answers: SiriAnswers, at instant: Date) -> String {
    answers.currentShift(at: instant)
  }
}

// MARK: - NextBigRunAndSplatfestIntent

/// When the next Big Run and the next Splatfest are.
public struct NextBigRunAndSplatfestIntent: QuestionIntent {
  static public let title: LocalizedStringResource = .init("Next Big Run and Splatfest", bundle: #bundle)

  public init() { }

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    try await AnswerSource.forIntents().result(of: self)
  }

  public func answer(from answers: SiriAnswers, at instant: Date) -> String {
    answers.nextBigRunAndSplatfest(at: instant)
  }
}
#endif
