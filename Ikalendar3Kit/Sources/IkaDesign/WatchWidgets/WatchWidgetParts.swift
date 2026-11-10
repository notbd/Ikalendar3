//
//  WatchWidgetParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(watchOS)
import IkaCore
import SwiftUI

// MARK: - WatchItem

/// What a watch widget writes of a Rotation or Shift: its title, the Rotation's Rule or the
/// Shift's Stage; the Rule whose icon goes beside it; and its window, which the countdown runs to
/// the end of.
struct WatchItem {
  let title: String
  let rule: RuleID?
  let startTime: Date
  let endTime: Date

  /// The window, as the system's countdown takes it.
  var window: ClosedRange<Date> { startTime ... endTime }

  /// A Rotation, titled by its Rule, or by its Battle Mode when it has none.
  init(_ rotation: Rotation, terms: GameTerms) {
    title = rotation.setting.map { terms.name(of: $0.rule) } ?? rotation.mode.name(in: terms.language)
    rule = rotation.setting?.rule
    startTime = rotation.startTime
    endTime = rotation.endTime
  }

  /// A Shift, titled by its Stage.
  init(_ shift: Shift, terms: GameTerms) {
    title = terms.name(of: shift.stage)
    rule = nil
    startTime = shift.startTime
    endTime = shift.endTime
  }
}

// MARK: - WatchCurrent

/// What a watch widget's Mode has on from the entry's date.
enum WatchCurrent {
  /// A Rotation or Shift is on.
  case item(WatchItem)
  /// A Splatfest pauses the Battle Mode, which returns at `returnTime`.
  case paused(BattleMode, returnTime: Date)
  /// Nothing is on.
  case nothing
}

// MARK: - WatchWidgetContent

extension WatchWidgetContent {
  /// The icon a watch widget shows: the shown Battle Mode's, Splatfest Battle's while it replaces
  /// the Battle Mode, or the current Shift's kind's, so a Big Run shows as one.
  var icon: ModeIcon {
    switch self {
      case .battle(let content): ModeIcon(content.shownMode)
      case .salmonRun(let content): ModeIcon(content.current.item?.kind ?? .regular)
    }
  }

  /// What the Mode has on, in `terms`.
  func current(in terms: GameTerms) -> WatchCurrent {
    switch self {
      case .battle(let content):
        switch content.current {
          case .item(let rotation): .item(WatchItem(rotation, terms: terms))
          case .paused(let returnTime): .paused(content.mode, returnTime: returnTime)
          case .nothingCurrent: .nothing
        }

      case .salmonRun(let content):
        content.current.item.map { .item(WatchItem($0, terms: terms)) } ?? .nothing
    }
  }

  /// The item after the current one, in `terms`, or `nil` when none is published.
  func next(in terms: GameTerms) -> WatchItem? {
    switch self {
      case .battle(let content): content.upcoming.first.map { WatchItem($0, terms: terms) }
      case .salmonRun(let content): content.upcoming.first.map { WatchItem($0, terms: terms) }
    }
  }

  /// How the item after the current one reads to VoiceOver: its sentence, with no time left.
  func nextAccessibility(writer: SentenceWriter) -> WidgetAccessibility? {
    switch self {
      case .battle(let content): content.upcoming
      .first
      .map { WidgetAccessibility($0, writer: writer, isCurrent: false) }

      case .salmonRun(let content): content.upcoming.first.map { WidgetAccessibility(
          $0,
          writer: writer,
          isCurrent: false) }
    }
  }
}

// MARK: - ModeHeading

extension ModeHeading {
  /// The heading of what a watch widget shows: the shown Battle Mode, or the current Shift's kind.
  init(_ content: WatchWidgetContent, in language: GameLanguage, @ViewBuilder trailing: () -> Trailing) {
    switch content {
      case .battle(let battle):
        self.init(mode: battle.shownMode, in: language, trailing: trailing)
      case .salmonRun(let salmonRun):
        self.init(kind: salmonRun.current.item?.kind ?? .regular, in: language, trailing: trailing)
    }
  }
}

// MARK: - WatchItemLabel

/// An item's title, after its Rule's icon when it has one, in `style`.
struct WatchItemLabel: View {
  let item: WatchItem
  let terms: GameTerms
  var style: InkTextStyle = .label

  var body: some View {
    if let rule = item.rule {
      RuleLabel(rule: rule, terms: terms, style: style)
    }
    else {
      Text(verbatim: item.title)
        .inkFont(style)
        .scaledLimitedLine()
    }
  }
}

// MARK: - WatchEmptyView

/// A watch widget's empty state before the schedules feed's first good response: the screens'
/// "No schedule yet".
struct WatchEmptyView: View {
  let language: GameLanguage

  var body: some View {
    Text(verbatim: ScreenText.empty.text(in: language))
      .inkFont(.label)
      .scaledLimitedLine(lineLimit: 2)
      .multilineTextAlignment(.center)
  }
}
#endif
