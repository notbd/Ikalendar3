//
//  WidgetAccessibility.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - WidgetAccessibility

/// What VoiceOver reads for an item a widget shows, as one element: the item's sentence as the
/// label, with no time left, because the system draws a widget ahead of the moment VoiceOver reads
/// it; for the item on now, the system's countdown to its end as the value, which the system keeps
/// current. Every widget extension reads its Rotations and Shifts through it.
public struct WidgetAccessibility: Equatable, Sendable {
  /// The item's sentence, with no time left.
  public let label: String
  /// The window the value counts down to its end, for the item on now; else `nil`.
  public let countdown: ClosedRange<Date>?

  /// How `rotation` reads in `writer`'s text set; `isCurrent` for the Rotation on now.
  public init(_ rotation: Rotation, writer: SentenceWriter, isCurrent: Bool) {
    label = writer.sentence(for: rotation)
    countdown = isCurrent ? rotation.startTime ... rotation.endTime : nil
  }

  /// How `shift` reads in `writer`'s text set; `isCurrent` for the Shift on now.
  public init(_ shift: Shift, writer: SentenceWriter, isCurrent: Bool) {
    label = writer.sentence(for: shift)
    countdown = isCurrent ? shift.startTime ... shift.endTime : nil
  }

  /// How what a Battle Mode has on reads: its current Rotation, its pause sentence, or that
  /// nothing is on. `note` follows the label, such as the stale mark's words where the mark sits
  /// inside the element.
  public init(_ current: WidgetCurrent<Rotation>, of mode: BattleMode, writer: SentenceWriter, note: String? = nil) {
    let item: Self =
      switch current {
        case .item(let rotation): .init(rotation, writer: writer, isCurrent: true)
        case .paused(let returnTime): .init(label: writer.sentence(forPauseOf: mode, returningAt: returnTime))
        case .nothingCurrent: .nothingCurrent(in: writer)
      }
    self.init(item, note: note)
  }

  /// How what a complication's Mode has on reads: a Battle Mode's as above, or Salmon Run's
  /// current Shift, or that nothing is on. `note` follows the label.
  public init(_ content: WatchWidgetContent, writer: SentenceWriter, note: String? = nil) {
    switch content {
      case .battle(let battle):
        self.init(battle.current, of: battle.mode, writer: writer, note: note)

      case .salmonRun(let salmonRun):
        let item: Self =
          switch salmonRun.current {
            case .item(let shift): .init(shift, writer: writer, isCurrent: true)
            // A Shift is never paused.
            case .paused,
                 .nothingCurrent: .nothingCurrent(in: writer)
          }
        self.init(item, note: note)
    }
  }

  /// `item` with `note` after its label.
  private init(_ item: Self, note: String?) {
    label = [item.label, note].compactMap(\.self).joined(separator: " ")
    countdown = item.countdown
  }

  private init(label: String) {
    self.label = label
    countdown = nil
  }

  /// "Nothing on right now", in `writer`'s text set.
  static private func nothingCurrent(in writer: SentenceWriter) -> Self {
    .init(label: ScreenText.nothingCurrent.text(in: writer.terms.language))
  }
}

extension View {
  /// Makes the view one VoiceOver element that reads as `accessibility` says.
  public func widgetAccessibility(_ accessibility: WidgetAccessibility) -> some View {
    accessibilityElement(children: .ignore)
      .accessibilityLabel(accessibility.label)
      .accessibilityValue(accessibility.countdown.map { Text(timerInterval: $0) } ?? Text(verbatim: ""))
  }
}
