//
//  ModePageView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - ModePageView

/// A Mode's page in Ink: the Mode's heading on its tint, then one panel with the current Rule or
/// Shift in a white ring that fills as it runs, or why none is on, and under a dotted rule the
/// next Rotation or Shift. A running Big Run heads Salmon Run's page as one, in its own colour.
/// It receives `IkaCore` values only and reads no store.
struct ModePageView: View {
  let page: ModePage
  let terms: GameTerms
  let now: Date

  var body: some View {
    let look: SummaryLook = .init(page.summary)

    VStack(alignment: .leading, spacing: WatchMetrics.rowSpacing) {
      PageHeading(heading: look.heading, color: look.color, language: terms.language)
      VStack(alignment: .leading, spacing: WatchMetrics.rowSpacing) {
        CurrentItem(summary: page.summary, look: look, terms: terms, now: now)
          // On a small watch the next item gives way first.
          .layoutPriority(1)
        switch page {
          case .battle(let screen):
            if let next = screen.next {
              InkDottedRule()
              RotationRow(rotation: next, terms: terms, now: now, isNext: true)
            }

          case .salmonRun(let screen):
            if let next = screen.next {
              InkDottedRule()
              ShiftRow(shift: next, terms: terms, now: now, isNext: true)
            }
        }
      }
      .inkPanel()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .contentShape(.rect)
  }
}

// MARK: - PageHeading

/// A Mode's name in the heavy face, readable on the top of its tint in `color`, with its form on a
/// tag: over a Mode page and its later list. VoiceOver reads it as a header.
struct PageHeading: View {
  let heading: InkModeHeading
  let color: ModeColor
  let language: GameLanguage

  var body: some View {
    HStack(spacing: WatchMetrics.lineSpacing) {
      Text(verbatim: heading.name.text(in: language))
        .ikaFont(.heavy, size: WatchMetrics.detailSize, relativeTo: .headline)
        .foregroundStyle(Color(color.asFill.foreground))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      if let form = heading.form {
        InkTimeTag(Text(verbatim: form.text(in: language)))
          // At its ideal size: left to shrink, the tag shrank the next item's row under it on
          // the watch (seen on Anarchy's pages).
          .fixedSize()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }
}

// MARK: - CurrentItem

/// The current Rule or Shift Stage in a white ring of the share passed, beside its name and the
/// time left, and a Shift's weapons under it; or the paused Battle Mode's return, or that nothing
/// is on, beside an empty ring around the Mode icon. One VoiceOver element reading the summary's
/// sentence, as the Now row does.
private struct CurrentItem: View {
  @Environment(\.colorScheme) private var colorScheme
  @TimeSettings private var time

  let summary: ModeSummary
  let look: SummaryLook
  let terms: GameTerms
  let now: Date

  var body: some View {
    VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing) {
      HStack(spacing: WatchMetrics.rowSpacing) {
        ZStack {
          ProgressRing(
            share: look.share,
            color: .white,
            lineWidth: WatchMetrics.ringLineWidth,
            timeLeft: look.progress.map(writer.timeLeft))
          picture
            .padding(WatchMetrics.ringLineWidth + WatchMetrics.iconInset)
        }
        .frame(width: WatchMetrics.pageRingSize, height: WatchMetrics.pageRingSize)

        VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing / 2) {
          Text(verbatim: look.detail(of: summary, terms: terms, format: format, now: now))
            .ikaFont(.heavy, size: WatchMetrics.detailSize, relativeTo: .headline)
            // The heavy face's tall line box leaves a gap between wrapped lines.
            .lineHeight(.tight)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
          if let progress = look.progress {
            Text(verbatim: writer.countdown(progress))
              .ikaFont(.light, size: WatchMetrics.countdownSize, relativeTo: .footnote)
              .monospacedDigit()
              .countdownRoll(value: now)
              .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
          }
        }
      }
      if case .salmonRun(.running(let running)) = summary {
        WeaponsRow(weapons: running.item.weapons, terms: terms)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: summary, at: now))
  }

  /// The picture in the ring: the current Rule's icon, the current Shift's Stage cut to a circle,
  /// or the Mode's icon while nothing runs.
  @ViewBuilder
  private var picture: some View {
    switch summary {
      case .battle(_, .running(let running)):
        // A summary's Rotation always plays.
        if let rule = running.item.setting?.rule {
          Image(decorative: BundledImage.name(for: rule, size: .small), bundle: BundledImage.catalogBundle)
            .resizable()
            .scaledToFit()
        }

      case .salmonRun(.running(let running)):
        Image(decorative: BundledImage.name(for: running.item.stage, size: .small), bundle: BundledImage.catalogBundle)
          .resizable()
          .scaledToFill()
          .clipShape(.circle)

      default:
        Image(decorative: BundledImage.name(for: look.icon, size: .small), bundle: BundledImage.catalogBundle)
          .resizable()
          .scaledToFit()
    }
  }

  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}
