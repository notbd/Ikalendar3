//
//  ClassicBattleCells.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicBattleSection

/// One row of Classic's Battle Mode or Splatfest Battle list: its header (tag and time range)
/// over the featured primary cell or a secondary cell, as ikalendar 2's `BattleRotationRow` draws
/// it.
///
/// The section owns the namespace its Rotation's Rule and Stages glide in, and keeps its identity
/// while the Rotation moves from a secondary cell to the primary one, so the Rotation glides into
/// the featured place when it becomes current.
struct ClassicBattleSection: View {
  @TimeSettings private var time
  @Environment(\.colorScheme) private var colorScheme

  @Namespace private var glide

  let row: ClassicBattleRow
  /// The Battle Mode or the form of Splatfest Battle the Rotation belongs to.
  let mode: RotationMode
  let terms: GameTerms
  let now: Date
  let metrics: CellMetrics
  /// Whether the header names the Battle Mode on its colour, as on Regular Battle's first
  /// Rotation after a Splatfest.
  var showsModeTag = false

  var body: some View {
    Section {
      cell
    } header: {
      header
        // The cell's sentence reads the time range.
        .accessibilityHidden(true)
    }
  }

  @ViewBuilder private var cell: some View {
    switch row {
      case .current(let running):
        // Never `nil`: IkaCore hands out only Rotations that play and reads a pause as
        // `.paused`, so these unwraps only satisfy `Rotation`'s optional `setting`.
        if let setting = running.item.setting {
          ClassicBattlePrimaryCell(
            setting: setting,
            progress: running.progress,
            tint: tint,
            terms: terms,
            now: now,
            metrics: metrics,
            glide: glide)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(writer.sentence(for: running.item, at: now))
        }

      case .upcoming(let rotation, _):
        if let setting = rotation.setting {
          ClassicBattleSecondaryCell(
            rule: setting.rule,
            stages: setting.stages,
            terms: terms,
            metrics: metrics,
            glide: glide)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(writer.sentence(for: rotation, at: now))
        }

      case .paused(let returnTime):
        let format = time.format(terms.language)
        let status: ClassicStatusCell = .init(
          text: ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: now)),
          arrangement: metrics.arrangement)
        // Only a Battle Mode is paused; a Splatfest Battle form never is.
        if case .battle(let battleMode) = mode {
          status.accessibilityLabel(writer.sentence(forPauseOf: battleMode, returningAt: returnTime))
        }
        else {
          status
        }

      case .nothingCurrent:
        ClassicStatusCell(text: ScreenText.nothingCurrent.text(in: terms.language), arrangement: metrics.arrangement)
    }
  }

  @ViewBuilder private var header: some View {
    let layout: AnyLayout = metrics.arrangement == .stacked
      ? AnyLayout(VStackLayout(alignment: .leading))
      : AnyLayout(HStackLayout(spacing: ClassicMetrics.Header.spacing))

    layout {
      if let tag = row.tag {
        ClassicTag(text: tag.text(in: terms.language))
      }
      if showsModeTag, case .battle(let battleMode) = mode {
        ClassicKindTag(text: mode.name(in: terms.language), color: ModeColor(battleMode))
      }
      if let window = row.window {
        Text(verbatim: timeFormat.battleRange(from: window.startTime, to: window.endTime, now: now))
          .scaledLimitedLine(for: metrics.arrangement)
          .ikaFont(.light, size: ClassicMetrics.Header.contentFontSize, relativeTo: .headline)
      }
    }
  }

  /// The progress bar's tint: the Battle Mode's colour. Splatfest Battle has no Mode colour of
  /// its own, and no one team's colour stands for it, so its bar stays neutral.
  private var tint: Color {
    switch mode {
      case .battle(let battleMode): ModeColor(battleMode).classicTint(in: colorScheme)
      case .splatfestBattle: .primary
    }
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - ClassicBattlePrimaryCell

/// The current Rotation's featured cell: the Rule's icon and name with the time left, the
/// progress bar, then both Stages with their names on glass labels.
///
/// Matched-geometry rule, as in ikalendar 2: this primary cell is the geometry source and the
/// secondary cell only matches it. The two coexist during the glide, where two sources would be
/// undefined, and the source must be the cell that stays: a non-source keeps the last frame of a
/// removed source, which would leave the new featured cell's Rule and Stages off the cell.
struct ClassicBattlePrimaryCell: View {
  typealias Scoped = ClassicMetrics.BattlePrimary

  @TimeSettings private var time

  let setting: Rotation.Setting
  let progress: WindowProgress
  let tint: Color
  let terms: GameTerms
  let now: Date
  let metrics: CellMetrics
  let glide: Namespace.ID

  var body: some View {
    VStack(alignment: .leading, spacing: Scoped.cellSpacingV) {
      switch metrics.arrangement {
        case .sideBySide:
          HStack(alignment: .center) {
            ruleSection
            Spacer()
            remainingTime
              .frame(width: metrics.length(.battleRemainingTimeWidth), alignment: .trailing)
          }

        case .stacked:
          ruleSection
          remainingTime
      }

      ProgressView(value: progress.sharePassed)
        .tint(tint)
        .padding(.bottom, Scoped.progressBarPaddingBottom)

      let stages: AnyLayout = metrics.arrangement == .stacked
        ? AnyLayout(VStackLayout(spacing: Scoped.stagesSpacingH))
        : AnyLayout(HStackLayout(spacing: Scoped.stagesSpacingH))
      stages {
        ForEach(Array(setting.stages.enumerated()), id: \.offset) { index, stage in
          ClassicBattleStageCard(
            stage: stage,
            name: terms.name(of: stage),
            role: .primary,
            arrangement: metrics.arrangement)
            .matchedGeometryEffect(id: GlidePart.stage(index), in: glide)
        }
      }
    }
    .padding(.bottom, Scoped.cellPaddingBottom)
  }

  private var ruleSection: some View {
    HStack(alignment: .center, spacing: Scoped.ruleSectionSpacing) {
      ClassicPicture(name: BundledImage.name(for: setting.rule, size: .large))
        .shadow(radius: ClassicMetrics.shadowRadius)
        .frame(height: metrics.arrangement == .stacked ? metrics.length(.battleRuleSectionHeight) : nil)
        .layoutPriority(1)
        .matchedGeometryEffect(id: GlidePart.ruleIcon, in: glide)

      ClassicPrimaryRuleTitle(rule: setting.rule, terms: terms, arrangement: metrics.arrangement)
        .padding(.vertical, Scoped.ruleTitlePaddingV)
        .matchedGeometryEffect(id: GlidePart.ruleTitle, in: glide)
    }
    .frame(
      width: metrics.arrangement == .sideBySide ? metrics.length(.battleRuleSectionWidth) : nil,
      height: metrics.arrangement == .sideBySide ? metrics.length(.battleRuleSectionHeight) : nil,
      alignment: .leading)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var remainingTime: some View {
    Text(verbatim: ClassicText.timeLeft.text(in: terms.language, timeFormat.span(progress.timeLeft)))
      .countdownRoll(value: now)
      .scaledLimitedLine(for: metrics.arrangement)
      .foregroundStyle(.secondary)
      .ikaFont(.light, size: Scoped.remainingTimeFontSize, relativeTo: .headline)
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }
}

// MARK: - ClassicPrimaryRuleTitle

/// The featured Rotation's Rule name, large and heavy, at the size that also fits every other
/// Rule's, so the title keeps one size from Rotation to Rotation; wrapped at full size when
/// stacked.
struct ClassicPrimaryRuleTitle: View {
  let rule: RuleID
  let terms: GameTerms
  let arrangement: CellArrangement

  var body: some View {
    switch arrangement {
      case .sideBySide:
        IdealFontLayout(anchor: .leading) {
          title(terms.name(of: rule))
          ForEach(RuleID.bundled, id: \.self) { rule in
            title(terms.name(of: rule))
          }
        }

      case .stacked:
        title(terms.name(of: rule))
    }
  }

  private func title(_ name: String) -> some View {
    Text(verbatim: name)
      .scaledLimitedLine(for: arrangement)
      .ikaFont(.heavy, size: ClassicMetrics.BattlePrimary.ruleTitleFontSize, relativeTo: .title)
  }
}

// MARK: - ClassicBattleSecondaryCell

/// A later Rotation's cell: the Rule's icon on glass over its name, beside both Stages with their
/// names under their pictures. It matches the primary cell's geometry, never sources it. A
/// Challenge shows its Rule and Stages in it too.
struct ClassicBattleSecondaryCell: View {
  typealias Scoped = ClassicMetrics.BattleSecondary

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  let rule: RuleID
  let stages: [StageID]
  let terms: GameTerms
  let metrics: CellMetrics
  let glide: Namespace.ID

  var body: some View {
    switch metrics.arrangement {
      case .sideBySide:
        HStack {
          VStack(spacing: Scoped.ruleSectionSpacing) {
            ruleIcon
            ruleTitle
              .frame(height: Scoped.ruleTitleHeight)
          }
          .frame(width: metrics.length(.battleSecondaryRuleSectionWidth))
          .padding(.trailing, Scoped.ruleSectionPaddingTrailing)

          BattleSecondaryStagesLayout {
            stageCards
          }
        }

      case .stacked:
        VStack(alignment: .leading) {
          HStack {
            ruleIcon
            ruleTitle
          }
          stageCards
        }
    }
  }

  private var ruleIcon: some View {
    ClassicPicture(name: BundledImage.name(for: rule, size: .medium))
      .shadow(radius: ClassicMetrics.shadowRadius)
      .frame(height: metrics.length(.battleSecondaryRuleImageHeight))
      .padding(Scoped.ruleImagePadding)
      .adaptiveGlassEffect(in: .rect(cornerRadius: Scoped.ruleImageCornerRadius))
      .matchedGeometryEffect(id: GlidePart.ruleIcon, in: glide, isSource: false)
  }

  /// The Rule's name; on a regular width at the size that fits every Rule's name, as ikalendar 2.
  @ViewBuilder private var ruleTitle: some View {
    if horizontalSizeClass != .compact, metrics.arrangement == .sideBySide {
      IdealFontLayout(anchor: .center) {
        title(terms.name(of: rule))
        ForEach(RuleID.bundled, id: \.self) { rule in
          title(terms.name(of: rule))
        }
      }
      .matchedGeometryEffect(id: GlidePart.ruleTitle, in: glide, isSource: false)
    }
    else {
      title(terms.name(of: rule))
        .matchedGeometryEffect(id: GlidePart.ruleTitle, in: glide, isSource: false)
    }
  }

  private func title(_ name: String) -> some View {
    Text(verbatim: name)
      .scaledLimitedLine(for: metrics.arrangement)
      .ikaFont(.light, size: Scoped.ruleFontSize, relativeTo: .body)
  }

  private var stageCards: some View {
    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
      ClassicBattleStageCard(
        stage: stage,
        name: terms.name(of: stage),
        role: .secondary,
        arrangement: metrics.arrangement)
        .matchedGeometryEffect(id: GlidePart.stage(index), in: glide, isSource: false)
    }
  }
}

// MARK: - ClassicBattleStageCard

/// A battle Stage's picture with its name: on a glass label over the picture in the featured
/// cell, under the picture in a later one and whenever the cell stacks, where a wrapped name
/// would cover the picture.
struct ClassicBattleStageCard: View {
  /// Which cell the card sits in.
  enum Role {
    case primary
    case secondary
  }

  let stage: StageID
  let name: String
  let role: Role
  let arrangement: CellArrangement

  var body: some View {
    switch (role, arrangement) {
      case (.primary, .sideBySide):
        picture
          .overlay(alignment: .bottomTrailing) {
            ClassicStageLabel(
              name: name,
              fontSize: ClassicMetrics.BattlePrimary.stageLabelFontSize,
              arrangement: arrangement)
              .padding(.leading, ClassicMetrics.BattlePrimary.stageLabelPaddingLeading)
              .padding([.bottom, .trailing], ClassicMetrics.BattlePrimary.stageLabelPaddingBottomTrailing)
          }

      case (.primary, .stacked),
           (.secondary, _):
        VStack(alignment: .trailing, spacing: ClassicMetrics.BattleSecondary.stageSpacingV) {
          picture
            .layoutPriority(1)
          Text(verbatim: name)
            .scaledLimitedLine(for: arrangement)
            .multilineTextAlignment(.trailing)
            .ikaFont(.light, size: ClassicMetrics.BattleSecondary.stageFontSize, relativeTo: .body)
        }
    }
  }

  @ViewBuilder private var picture: some View {
    let cornerRadius: CGFloat = role == .primary
      ? ClassicMetrics.BattlePrimary.stageCornerRadius
      : ClassicMetrics.BattleSecondary.stageCornerRadius
    let image = ClassicPicture(name: BundledImage.name(for: stage, size: role == .primary ? .large : .medium))
      .clipShape(.rect(cornerRadius: cornerRadius))

    switch role {
      case .primary:
        image
          .adaptiveGlassEffect(in: .rect(cornerRadius: cornerRadius))
          .shadow(radius: ClassicMetrics.shadowRadius)

      case .secondary:
        image
          .glassEffect(.clear.interactive(), in: .rect(cornerRadius: cornerRadius))
          .shadow(radius: ClassicMetrics.shadowRadius)
    }
  }
}

// MARK: - GlidePart

/// The parts of a Rotation that glide from a secondary cell into the featured one.
private enum GlidePart: Hashable {
  case ruleIcon
  case ruleTitle
  case stage(Int)
}

// MARK: - ClassicBattleRow

extension ClassicBattleRow {
  /// The Rotation's window, or `nil` for a status row.
  fileprivate var window: Rotation? {
    switch self {
      case .current(let running): running.item
      case .upcoming(let rotation, _): rotation
      case .paused,
           .nothingCurrent: nil
    }
  }
}

// MARK: - RuleID

extension RuleID {
  /// Every Rule the build bundles an icon for, which a Rule title sizes itself against.
  static let bundled: [RuleID] = (BundledImage.baseNames[.rule] ?? [:]).keys.sorted().map { RuleID($0) }
}
#endif
