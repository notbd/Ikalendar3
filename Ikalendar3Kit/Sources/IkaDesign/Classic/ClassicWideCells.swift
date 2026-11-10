//
//  ClassicWideCells.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicWideBattleCell

/// The wide detail's current Rotation: "Now:" and the time range, the Rule's icon and name, and
/// the progress ring with the time left on the left half; both Stages with their names on glass
/// labels on the right half. VoiceOver reads it as one element, the Rotation's sentence.
struct ClassicWideBattleCell: View {
  @TimeSettings private var time
  @Environment(\.colorScheme) private var colorScheme

  let running: Running<Rotation>
  /// The Battle Mode or the form of Splatfest Battle the Rotation belongs to.
  let mode: RotationMode
  let terms: GameTerms
  let now: Date
  let wide: WideDetailMetrics

  var body: some View {
    let rotation: Rotation = running.item

    // A Battle Mode's current Rotation always plays: a pause is never a running item.
    if let setting = rotation.setting {
      ClassicWideRow {
        VStack(alignment: .leading, spacing: ClassicMetrics.BattlePrimary.cellSpacingV) {
          HStack(spacing: ClassicMetrics.Header.spacing) {
            ClassicTag(text: ClassicText.now.text(in: terms.language))
            ClassicWideTimeText(text: timeFormat.battleRange(from: rotation.startTime, to: rotation.endTime, now: now))
          }
          HStack(spacing: ClassicMetrics.BattlePrimary.ruleSectionSpacing) {
            ClassicPicture(name: BundledImage.name(for: setting.rule, size: .large))
              .shadow(radius: ClassicMetrics.shadowRadius)
              .frame(height: wide.half.length(.battleRuleSectionHeight))
            ClassicPrimaryRuleTitle(rule: setting.rule, terms: terms, arrangement: .sideBySide)
              .frame(height: wide.half.length(.battleRuleSectionHeight))
          }
          ClassicWideProgress(progress: running.progress, tint: tint, terms: terms, now: now, wide: wide)
        }
      } trailing: {
        HStack(spacing: ClassicMetrics.BattlePrimary.stagesSpacingH) {
          ForEach(Array(setting.stages.enumerated()), id: \.offset) { _, stage in
            ClassicBattleStageCard(stage: stage, name: terms.name(of: stage), role: .primary, arrangement: .sideBySide)
          }
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(writer.sentence(for: rotation, at: now))
    }
  }

  /// The ring's tint: the Battle Mode's colour; neutral for Splatfest Battle, which has none.
  private var tint: Color {
    switch mode {
      case .battle(let battleMode): ModeColor(battleMode).classicTint(in: colorScheme)
      case .splatfestBattle: .primary
    }
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - ClassicBattleTableRow

/// A later Rotation's row in the wide detail's table: "Next:" on the first and the time range,
/// the Rule's icon and name, and two small Stage thumbnails with their names. VoiceOver reads it
/// as one element, the Rotation's sentence.
struct ClassicBattleTableRow: View {
  @TimeSettings private var time

  let rotation: Rotation
  let isNext: Bool
  let terms: GameTerms
  let now: Date
  let wide: WideDetailMetrics

  var body: some View {
    // A lineup's Rotations always play.
    if let setting = rotation.setting {
      ClassicTableRow(wide: wide) {
        if isNext {
          ClassicTag(text: ClassicText.next.text(in: terms.language))
        }
        ClassicWideTimeText(text: timeFormat.battleRange(from: rotation.startTime, to: rotation.endTime, now: now))
      } middle: {
        HStack(spacing: ClassicMetrics.BattlePrimary.ruleSectionSpacing) {
          ClassicPicture(name: BundledImage.name(for: setting.rule, size: .medium))
            .shadow(radius: ClassicMetrics.shadowRadius)
            .frame(height: wide.half.length(.tableRuleIconHeight))
          Text(verbatim: terms.name(of: setting.rule))
            .scaledLimitedLine(for: .sideBySide)
            .ikaFont(.light, size: ClassicMetrics.BattleSecondary.ruleFontSize, relativeTo: .body)
        }
      } trailing: {
        ForEach(Array(setting.stages.enumerated()), id: \.offset) { _, stage in
          ClassicBattleStageCard(stage: stage, name: terms.name(of: stage), role: .secondary, arrangement: .sideBySide)
            .frame(width: wide.half.length(.tableThumbnailWidth))
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(writer.sentence(for: rotation, at: now))
    }
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - ClassicWideShiftCell

/// The wide detail's running Shift: "Open!", its kind and its time range, the kind's icon, and
/// the progress ring with the time left on the left half; the Stage with its King Salmonid
/// beside the four weapons on the right half. VoiceOver reads it as one element, the Shift's
/// sentence.
struct ClassicWideShiftCell: View {
  @TimeSettings private var time
  @Environment(\.colorScheme) private var colorScheme

  let shift: Shift
  let progress: WindowProgress
  let tag: ClassicSalmonRunRow.Tag?
  let terms: GameTerms
  let now: Date
  let wide: WideDetailMetrics

  var body: some View {
    ClassicWideRow {
      VStack(alignment: .leading, spacing: ClassicMetrics.BattlePrimary.cellSpacingV) {
        ClassicShiftTags(shift: shift, tag: tag, terms: terms)
        ClassicWideTimeText(text: timeFormat.range(of: shift, now: now))
        ClassicPicture(name: BundledImage.name(for: ModeIcon(shift.kind), size: .medium))
          .shadow(radius: ClassicMetrics.shadowRadius)
          .frame(height: wide.half.length(.battleRuleSectionHeight))
        ClassicWideProgress(
          progress: progress,
          tint: ModeColor(shift.kind).classicTint(in: colorScheme),
          terms: terms,
          now: now,
          wide: wide)
      }
    } trailing: {
      SalmonStageAndWeaponsLayout {
        ClassicShiftStageCard(
          stage: shift.stage,
          stageName: terms.name(of: shift.stage),
          kingSalmonid: shift.kingSalmonid,
          isRunning: true,
          arrangement: .sideBySide)
        ClassicWeaponsCard(weapons: shift.weapons, terms: terms, columnCount: 2)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: shift, at: now))
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - ClassicShiftTableRow

/// A Shift's row in the wide detail's table: its tags and time range, with the countdown to its
/// start on the Soon one, the Stage thumbnail with its name, and the four weapons. VoiceOver
/// reads it as one element, the Shift's sentence.
struct ClassicShiftTableRow: View {
  @TimeSettings private var time

  let shift: Shift
  let tag: ClassicSalmonRunRow.Tag?
  let terms: GameTerms
  let now: Date
  let wide: WideDetailMetrics

  var body: some View {
    ClassicTableRow(wide: wide) {
      ClassicShiftTags(shift: shift, tag: tag, terms: terms)
      ClassicWideTimeText(text: timeFormat.range(of: shift, now: now))
      if tag == .soon {
        Text(verbatim: ClassicText.timeUntil.text(
          in: terms.language,
          timeFormat.span(.seconds(shift.startTime.timeIntervalSince(now)))))
          .countdownRoll(value: now)
          .scaledLimitedLine(for: .sideBySide)
          .foregroundStyle(.secondary)
          .ikaFont(.light, size: ClassicMetrics.BattlePrimary.remainingTimeFontSize, relativeTo: .headline)
      }
    } middle: {
      ClassicBattleStageCard(
        stage: shift.stage,
        name: terms.name(of: shift.stage),
        role: .secondary,
        arrangement: .sideBySide)
        .frame(width: wide.half.length(.tableThumbnailWidth))
    } trailing: {
      ForEach(Array(shift.weapons.enumerated()), id: \.offset) { _, weapon in
        Image(BundledImage.name(for: weapon, size: .medium), bundle: BundledImage.catalogBundle)
          .antialiased(true)
          .resizable()
          .scaledToFit()
          .shadow(radius: ClassicMetrics.shadowRadius)
          .padding(ClassicMetrics.Shift.weaponPadding)
          .frame(width: wide.half.length(.tableWeaponSize), height: wide.half.length(.tableWeaponSize))
          .adaptiveGlassEffect(in: .rect(cornerRadius: ClassicMetrics.Shift.weaponCornerRadius))
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: shift, at: now))
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - ClassicWideRow

/// The wide current row's two halves, padded as Classic pads its cells.
private struct ClassicWideRow<Leading: View, Trailing: View>: View {
  @ViewBuilder let leading: Leading
  @ViewBuilder let trailing: Trailing

  var body: some View {
    WideRowHalves(spacing: ClassicMetrics.Header.spacing) {
      leading
    } trailing: {
      trailing
    }
    .padding(.vertical, ClassicMetrics.Shift.cellPaddingV)
  }
}

// MARK: - ClassicTableRow

/// A table row's three columns, padded as Classic pads its cells.
private struct ClassicTableRow<Time: View, Middle: View, Trailing: View>: View {
  let wide: WideDetailMetrics
  @ViewBuilder let time: Time
  @ViewBuilder let middle: Middle
  @ViewBuilder let trailing: Trailing

  var body: some View {
    WideTableColumns(wide: wide, spacing: ClassicMetrics.Header.spacing) {
      time
    } middle: {
      middle
    } trailing: {
      trailing
    }
    .padding(.vertical, ClassicMetrics.Shift.cellPaddingV)
  }
}

// MARK: - ClassicWideProgress

/// The wide current row's progress ring, tinted with the Mode's colour, with the time left
/// beside it.
private struct ClassicWideProgress: View {
  @TimeSettings private var time

  /// The ring's stroke, as a share of its side.
  static private let lineWidthShare: CGFloat = 0.2

  let progress: WindowProgress
  let tint: Color
  let terms: GameTerms
  let now: Date
  let wide: WideDetailMetrics

  var body: some View {
    let side: CGFloat = wide.half.length(.wideRingSize)
    let format: ClassicTimeFormat = time.classicFormat(terms.language)

    HStack(spacing: ClassicMetrics.BattlePrimary.ruleSectionSpacing) {
      ProgressRing(
        share: progress.sharePassed,
        color: tint,
        lineWidth: side * Self.lineWidthShare)
        .frame(width: side, height: side)
      Text(verbatim: ClassicText.timeLeft.text(in: terms.language, format.span(progress.timeLeft)))
        .countdownRoll(value: now)
        .scaledLimitedLine(for: .sideBySide)
        .foregroundStyle(.secondary)
        .ikaFont(.light, size: ClassicMetrics.BattlePrimary.remainingTimeFontSize, relativeTo: .headline)
    }
  }
}

// MARK: - ClassicShiftTags

/// A Shift's tags in the wide detail: "Open!", "Soon:" or "Next:", and its kind's name on its
/// colour for a Big Run or an Eggstra Work.
private struct ClassicShiftTags: View {
  let shift: Shift
  let tag: ClassicSalmonRunRow.Tag?
  let terms: GameTerms

  var body: some View {
    if tag != nil || shift.kind.label != nil {
      HStack(spacing: ClassicMetrics.Header.spacing) {
        if let tag {
          ClassicTag(text: tag.text.text(in: terms.language))
        }
        if let label = shift.kind.label {
          ClassicKindTag(text: label.text(in: terms.language), color: ModeColor(shift.kind))
        }
      }
    }
  }
}

// MARK: - ClassicWideTimeText

/// A time range in the wide detail, in the header's light face.
private struct ClassicWideTimeText: View {
  let text: String

  var body: some View {
    Text(verbatim: text)
      .scaledLimitedLine(for: .sideBySide)
      .ikaFont(.light, size: ClassicMetrics.Header.contentFontSize, relativeTo: .headline)
  }
}

#endif
