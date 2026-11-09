//
//  SidebarRowContent.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - SidebarRowContent

/// What a sidebar row shows, the same in every Style: the Mode's icon in a ring of the share
/// passed, its name, one line with its current item and time left (or why none is on), and the
/// sentence VoiceOver reads for the row as one element. Each Style only draws it.
public struct SidebarRowContent: Equatable, Sendable {
  /// The icon inside the ring: the Mode's, or a Big Run's while one is Salmon Run's current Shift.
  public let icon: ModeIcon
  /// The ring's colour, or `nil` for the Splatfest's rows, which have none and take the Style's
  /// neutral colour.
  public let color: ModeColor?
  /// The row's name: the Mode's, or the form's alone under the Splatfest group.
  public let name: String
  /// The line under the name.
  public let summary: String
  /// How far the current item has run, which fills the ring, or `nil` while none is on.
  public let progress: WindowProgress?
  /// Whether the Splatfest keeps the row's Mode from play now.
  public let isDimmed: Bool
  /// What VoiceOver reads for the row: its sentence, or its name when the sentence names the
  /// Challenge instead (`accessibilityValue` then holds the sentence).
  public let accessibilityLabel: String
  /// The Challenge row's sentence, read after its name; `nil` for every other row.
  public let accessibilityValue: String?

  /// The content of `row` at `now`, in `writer`'s text set, with times in `format`.
  public init(row: SidebarRow, writer: SentenceWriter, format: ScheduleFormat, now: Date) {
    let terms = writer.terms
    let language = terms.language
    func line(_ item: String, _ progress: WindowProgress) -> String {
      "\(item) · \(writer.timeLeft(progress))"
    }
    func startsAt(_ instant: Date) -> String {
      SidebarText.startsAt.text(in: language, format.time(instant, relativeTo: now))
    }
    func whyNoneIsOn(_ onNow: OnNow<some TimeWindow>) -> String {
      switch onNow {
        case .running: ""
        case .paused(let returnTime): ScreenText.paused.text(in: language, format.time(returnTime, relativeTo: now))
        case .nothingCurrent: ScreenText.nothingCurrent.text(in: language)
      }
    }

    isDimmed = row.isDimmed
    switch row {
      case .mode(.battle(let mode, let onNow)):
        icon = ModeIcon(Mode.battle(mode))
        color = ModeColor(mode)
        name = mode.name(in: language)
        (summary, progress) = Self.rotationLine(onNow, terms: terms, line: line, else: whyNoneIsOn(onNow))

      case .mode(.salmonRun(.running(let running))):
        icon = ModeIcon(running.item.kind)
        color = ModeColor(running.item.kind)
        name = Mode.salmonRun.name(in: language)
        summary = line(terms.name(of: running.item.stage), running.progress)
        progress = running.progress

      case .mode(.salmonRun(let onNow)):
        icon = .salmonRun
        color = .salmonRun
        name = Mode.salmonRun.name(in: language)
        summary = whyNoneIsOn(onNow)
        progress = nil

      case .challenge(let window):
        icon = .challenge
        color = .challenge
        name = ModeLabel.challenges.text(in: language)
        switch window {
          case .running(let running)?:
            summary = line(terms.challenge(running.item.challenge.id).name, running.progress)
            progress = running.progress

          case .next(let next)?:
            summary = "\(terms.challenge(next.challenge.id).name) · \(startsAt(next.startTime))"
            progress = nil

          case nil:
            summary = SidebarText.noneAnnounced.text(in: language)
            progress = nil
        }

      case .eggstraWork(let running):
        icon = .eggstraWork
        color = .eggstraWork
        name = ModeLabel.eggstraWork.text(in: language)
        summary = line(terms.name(of: running.item.stage), running.progress)
        progress = running.progress

      case .splatfest(let running):
        icon = .splatfestBattle
        color = nil
        name = ModeLabel.splatfest.text(in: language)
        summary = line(terms.splatfest(running.item.id).title, running.progress)
        progress = running.progress

      case .splatfestBattle(let form, let onNow):
        icon = .splatfestBattle
        color = nil
        name = form.label.text(in: language)
        (summary, progress) = Self.rotationLine(onNow, terms: terms, line: line, else: whyNoneIsOn(onNow))

      case .tricolorTurfWar(let tricolorTurfWar):
        icon = .splatfestBattle
        color = nil
        name = ModeLabel.tricolor.text(in: language)
        switch tricolorTurfWar {
          case .running(let running):
            let stages = running.item.stages.map(terms.name(of:))
            summary = line(
              stages.formatted(.list(type: .and).locale(Locale(identifier: language.rawValue))),
              running.progress)
            progress = running.progress

          case .next(let next):
            summary = startsAt(next.startTime)
            progress = nil
        }
    }

    let sentence = writer.sentence(for: row, at: now)
    if case .challenge = row {
      accessibilityLabel = name
      accessibilityValue = sentence
    }
    else {
      accessibilityLabel = sentence
      accessibilityValue = nil
    }
  }

  /// A Rotation's line, its Rule and time left, and its progress while one runs; else `whyNot`.
  static private func rotationLine(
    _ onNow: OnNow<Rotation>,
    terms: GameTerms,
    line: (String, WindowProgress) -> String,
    else whyNot: String)
    -> (String, WindowProgress?)
  {
    // A summary's Rotation always plays: a paused window reads as the pause instead.
    guard case .running(let running) = onNow, let setting = running.item.setting else { return (whyNot, nil) }

    return (line(terms.name(of: setting.rule), running.progress), running.progress)
  }
}

// MARK: - SplatfestBattleForm

extension SplatfestBattleForm {
  /// The form's own label, which names its row under the Splatfest group.
  fileprivate var label: ModeLabel {
    switch self {
      case .open: .open
      case .pro: .pro
    }
  }
}
