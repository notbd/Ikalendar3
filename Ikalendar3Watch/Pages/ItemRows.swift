//
//  ItemRows.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - RotationRow

/// A Rotation after the current one: its start, marked Next on a Mode page, then its Rule; in the
/// later list its two Stages too. One VoiceOver element reading the Rotation's sentence, which
/// names the start's weekday when it is not today.
struct RotationRow: View {
  @Environment(\.colorScheme) private var colorScheme
  @TimeSettings private var time

  let rotation: Rotation
  let terms: GameTerms
  let now: Date
  /// Whether the row is a Mode page's next Rotation, rather than one in the later list.
  let isNext: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing / 2) {
      ItemTime(text: when, isNext: isNext, language: terms.language)
      // A lineup's Rotations always play.
      if let setting = rotation.setting {
        RuleLabel(rule: setting.rule, terms: terms, style: .tag)
        if !isNext {
          ForEach(setting.stages, id: \.self) { stage in
            Text(verbatim: terms.name(of: stage))
              .inkFont(.label)
              .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
              .scaledLimitedLine()
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(time.writer(terms).sentence(for: rotation, at: now))
  }

  /// The start, with its weekday and date when it is not today.
  private var when: String {
    time.format(terms.language).time(rotation.startTime, relativeTo: now)
  }
}

// MARK: - ShiftRow

/// A Shift after the current one: its start marked Next on a Mode page, or its time range with
/// the weekdays in the later list; a Big Run's tag, then its Stage; in the later list its four
/// weapons too. One VoiceOver element reading the Shift's sentence.
struct ShiftRow: View {
  @TimeSettings private var time

  let shift: Shift
  let terms: GameTerms
  let now: Date
  /// Whether the row is a Mode page's next Shift, rather than one in the later list.
  let isNext: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing / 2) {
      ItemTime(text: when, isNext: isNext, language: terms.language)
      HStack(spacing: WatchMetrics.lineSpacing) {
        if let label = shift.kind.label {
          InkModeTag(Text(verbatim: label.text(in: terms.language)), modeColor: ModeColor(shift.kind))
        }
        Text(verbatim: terms.name(of: shift.stage))
          .inkFont(.tag)
          .scaledLimitedLine()
      }
      if !isNext {
        WeaponsRow(weapons: shift.weapons, terms: terms)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(time.writer(terms).sentence(for: shift, at: now))
  }

  /// The start on a Mode page, where a range would not fit beside Next, with its weekday and date
  /// when it is not today; else the time range with the weekdays.
  private var when: String {
    let format = time.format(terms.language)
    return isNext ? format.time(shift.startTime, relativeTo: now) : format.timeRange(of: shift, withWeekday: true)
  }
}

// MARK: - ItemTime

/// When an item runs, after Next on a Mode page's next item, in the panel's secondary colour.
private struct ItemTime: View {
  @Environment(\.colorScheme) private var colorScheme

  let text: String
  let isNext: Bool
  let language: GameLanguage

  var body: some View {
    HStack(spacing: WatchMetrics.lineSpacing) {
      if isNext {
        Text(verbatim: InkText.next.text(in: language))
          .inkFont(.label)
      }
      Text(verbatim: text)
        .inkFont(.label)
        .monospacedDigit()
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
    }
    .scaledLimitedLine(minScaleFactor: 0.6)
  }
}

// MARK: - WeaponsRow

/// A Shift's four weapons in one row, on round dark plates, as the game shows them. Decorative:
/// the row's sentence names them.
struct WeaponsRow: View {
  @Environment(\.colorScheme) private var colorScheme

  let weapons: [WeaponID]
  let terms: GameTerms

  var body: some View {
    HStack(spacing: WatchMetrics.lineSpacing) {
      // Keyed by position: a Shift can list one weapon more than once (four golden marks).
      ForEach(Array(weapons.enumerated()), id: \.offset) { _, weapon in
        Image(decorative: BundledImage.name(for: weapon, size: .small), bundle: BundledImage.catalogBundle)
          .resizable()
          .scaledToFit()
          .padding(2)
          .frame(width: WatchMetrics.weaponSize, height: WatchMetrics.weaponSize)
          .background(Color(InkPair.tagText.colors(in: colorScheme).background), in: .circle)
      }
    }
  }
}
