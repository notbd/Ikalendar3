//
//  SummaryRowContent.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - SummaryRowContent

/// What a summary row shows, the same in every Style and on every Surface that lists Modes at a
/// glance (the iPad sidebar, the Series and Open menu, the Mac menu bar window and Overview cards,
/// the watch's Now rows and Mode pages): the icon in a ring of the share passed, the name, the current item with
/// the time left (or when it starts, or why none is on), and the sentence VoiceOver reads for the
/// row as one element. Each Surface only draws it.
public struct SummaryRowContent: Equatable, Sendable {
  /// The icon inside the ring: the Mode's, or the Shift kind's while a Big Run is Salmon Run's
  /// current Shift.
  public let icon: ModeIcon
  /// The Mode's or event's colour, or `nil` for the Splatfest's rows, which have none: each Style
  /// draws them in its neutral colour (Classic's and the system's primary, white in Ink and
  /// Timeline), never in a Mode's.
  public let color: ModeColor?
  /// The row's name: the Mode's, a running Big Run's, or a form's or event's alone under the
  /// Splatfest.
  public let name: String
  /// What is on: the current Rule, Stage, Challenge or Splatfest; or when it starts, or why none
  /// is on.
  public let detail: String
  /// The line under the name: the detail, with the time left while an item runs.
  public let line: String
  /// How far the current item has run, which fills the ring, or `nil` while none is on.
  public let progress: WindowProgress?
  /// Whether the Splatfest keeps the row's Mode from play now.
  public let isDimmed: Bool
  /// What VoiceOver reads for the row: its sentence, or its name when the sentence names the
  /// Challenge instead (`accessibilityValue` then holds the sentence).
  public let accessibilityLabel: String
  /// The Challenge row's sentence, read after its name; `nil` for every other row.
  public let accessibilityValue: String?

  /// The content of a Mode summary's row at `now`, the sidebar's row of it.
  public init(_ summary: ModeSummary, writer: SentenceWriter, format: ScheduleFormat, now: Date) {
    self.init(row: .mode(summary), writer: writer, format: format, now: now)
  }

  /// The content of `row` at `now`, in `writer`'s text set, with times in `format`.
  public init(row: SidebarRow, writer: SentenceWriter, format: ScheduleFormat, now: Date) {
    let terms = writer.terms
    let language = terms.language
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
      case .mode(let summary):
        icon = ModeIcon(summary)
        color = ModeColor(summary)
        switch summary {
          case .battle(let mode, let onNow):
            name = RotationMode.battle(mode).shortName(in: language)
            (detail, progress) = Self.rotation(onNow, terms: terms, else: whyNoneIsOn(onNow))

          case .splatfestBattle(let form, let onNow):
            name = RotationMode.splatfestBattle(form).shortName(in: language)
            (detail, progress) = Self.rotation(onNow, terms: terms, else: whyNoneIsOn(onNow))

          case .salmonRun(.running(let running)):
            name = ModeLabel(running.item.kind).text(in: language)
            detail = terms.name(of: running.item.stage)
            progress = running.progress

          case .salmonRun(let onNow):
            name = Mode.salmonRun.name(in: language)
            detail = whyNoneIsOn(onNow)
            progress = nil
        }

      case .challenge(let window):
        icon = .challenge
        color = .challenge
        name = ModeLabel.challenges.text(in: language)
        switch window {
          case .running(let running)?:
            detail = terms.challenge(running.item.challenge.id).name
            progress = running.progress

          case .next(let next)?:
            detail = "\(terms.challenge(next.challenge.id).name) · \(startsAt(next.startTime))"
            progress = nil

          case nil:
            detail = SidebarText.noneAnnounced.text(in: language)
            progress = nil
        }

      case .eggstraWork(let running):
        icon = .eggstraWork
        color = .eggstraWork
        name = ModeLabel.eggstraWork.text(in: language)
        detail = terms.name(of: running.item.stage)
        progress = running.progress

      case .splatfest(let running):
        icon = .splatfestBattle
        color = nil
        name = ModeLabel.splatfest.text(in: language)
        detail = terms.splatfest(running.item.id).title
        progress = running.progress

      case .tricolorTurfWar(let tricolorTurfWar):
        icon = .splatfestBattle
        color = nil
        name = ModeLabel.tricolor.text(in: language)
        switch tricolorTurfWar {
          case .running(let running):
            detail = writer.list(running.item.stages.map(terms.name(of:)))
            progress = running.progress

          case .next(let next):
            detail = startsAt(next.startTime)
            progress = nil
        }
    }
    if let progress {
      line = "\(detail) · \(writer.timeLeft(progress))"
    }
    else {
      line = detail
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

  /// A Rotation's Rule and its progress while one runs; else `whyNot` and no progress.
  static private func rotation(
    _ onNow: OnNow<Rotation>,
    terms: GameTerms,
    else whyNot: String)
    -> (String, WindowProgress?)
  {
    // A summary's Rotation always plays: a paused window reads as the pause instead.
    guard case .running(let running) = onNow, let setting = running.item.setting else { return (whyNot, nil) }

    return (terms.name(of: setting.rule), running.progress)
  }
}
