//
//  ClassicChallengeCells.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicChallengeSection

/// One Challenge in Classic's Challenge list: a cell with its name, description, Rule, Stages and
/// rules text, then one row per window with ikalendar 2's "Now:" and "Next:" tags, the current
/// window carrying its progress bar.
struct ClassicChallengeSection: View {
  typealias Scoped = ClassicMetrics.Challenge

  @Environment(\.colorScheme) private var colorScheme
  @TimeSettings private var time

  /// The secondary cell's matched geometry needs a namespace; nothing glides here.
  @Namespace private var glide

  let listing: ChallengeScreen.Listing
  let terms: GameTerms
  let now: Date
  let metrics: CellMetrics

  var body: some View {
    Section {
      details
      ForEach(listing.windows, id: \.window) { window in
        windowRow(window)
      }
    }
  }

  // MARK: Details

  private var details: some View {
    let challenge: Challenge = listing.challenge
    let texts: ChallengeTerms = terms.challenge(challenge.id)

    return VStack(alignment: .leading, spacing: Scoped.cellSpacingV) {
      Text(verbatim: texts.name)
        .classicLines(for: metrics.arrangement)
        .ikaFont(.heavy, size: Scoped.nameFontSize, relativeTo: .title2)
        // The heavy face is wide: past this size its longest word ("Jump-a-thon") no longer fits a
        // 390-point iPhone's cell and splits.
        .dynamicTypeSize(...ClassicMetrics.displayTitleLargestSize)
      if !texts.description.isEmpty {
        Text(verbatim: texts.displayDescription)
          .fixedSize(horizontal: false, vertical: true)
          .lineHeight(.multiple(factor: ClassicMetrics.wrappedLineHeightFactor))
          .ikaFont(.light, size: Scoped.descriptionFontSize, relativeTo: .headline)
      }
      ClassicBattleSecondaryCell(
        rule: challenge.rule,
        stages: challenge.stages,
        terms: terms,
        metrics: metrics,
        glide: glide)
        // At its ideal height: the stack offers it less, and the Stage cards gave the cut to
        // their names, which shrank to a few points.
        .fixedSize(horizontal: false, vertical: true)
      if !texts.rulesText.isEmpty {
        Text(verbatim: texts.displayRulesText)
          .fixedSize(horizontal: false, vertical: true)
          .lineHeight(.multiple(factor: ClassicMetrics.wrappedLineHeightFactor))
          .foregroundStyle(.secondary)
          .ikaFont(.light, size: Scoped.rulesTextFontSize, relativeTo: .footnote)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, Scoped.cellPaddingV)
    .accessibilityElement(children: .combine)
  }

  // MARK: Windows

  /// A window's row: its tag and time range, and while it runs its progress bar with the time
  /// left. A window that is over is dimmed. VoiceOver reads it as one sentence.
  private func windowRow(_ marked: ChallengeScreen.MarkedWindow) -> some View {
    let header: AnyLayout = metrics.arrangement == .stacked
      ? AnyLayout(VStackLayout(alignment: .leading))
      : AnyLayout(HStackLayout(spacing: ClassicMetrics.Header.spacing))

    return VStack(alignment: .leading, spacing: Scoped.windowSpacingV) {
      header {
        if let tag = marked.mark.classicTag {
          ClassicTag(text: tag.text(in: terms.language))
        }
        Text(verbatim: timeFormat.battleRange(from: marked.window.startTime, to: marked.window.endTime, now: now))
          .classicLines(for: metrics.arrangement)
          .ikaFont(.light, size: ClassicMetrics.Header.contentFontSize, relativeTo: .headline)
      }

      if case .current(let progress) = marked.mark {
        ClassicProgressBar(
          progress: progress,
          tint: ModeColor.challenge.classicTint(in: colorScheme),
          terms: terms,
          now: now,
          arrangement: metrics.arrangement)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .foregroundStyle(marked.mark == .over ? .secondary : .primary)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(
      for: ChallengeWindow(challenge: listing.challenge, window: marked.window),
      at: now))
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }

  private var writer: SentenceWriter { time.writer(terms) }
}
#endif
