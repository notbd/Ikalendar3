//
//  NowRow.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - NowRow

/// One Mode's row on the Now page: the Mode's name across the top, then the Mode icon in a ring
/// of the share passed beside the current Rule or the Shift's Stage and the time left; or when
/// the Battle Mode returns from a Splatfest's pause, or that nothing is on. A running Big Run
/// shows as one, in its own icon and colour. The page sets the rows on Ink's dark panel.
///
/// It is one VoiceOver element reading the summary's sentence. It receives `IkaCore` values only.
struct NowRow: View {
  @Environment(\.colorScheme) private var colorScheme
  @TimeSettings private var time

  let summary: ModeSummary
  let terms: GameTerms
  let now: Date

  var body: some View {
    let look: SummaryLook = .init(summary)
    let heading = look.heading

    VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing) {
      HStack(spacing: WatchMetrics.lineSpacing) {
        Text(verbatim: heading.name.text(in: terms.language))
          .ikaFont(.heavy, size: WatchMetrics.modeNameSize, relativeTo: .footnote)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        if let form = heading.form {
          InkModeTag(Text(verbatim: form.text(in: terms.language)), modeColor: look.color)
        }
      }

      HStack(spacing: WatchMetrics.rowSpacing) {
        ZStack {
          ProgressRing(
            share: look.share,
            color: Color(look.color.base),
            lineWidth: WatchMetrics.ringLineWidth,
            timeLeft: look.progress.map(writer.timeLeft))
          Image(decorative: BundledImage.name(for: look.icon, size: .small), bundle: BundledImage.catalogBundle)
            .resizable()
            .scaledToFit()
            .padding(WatchMetrics.ringLineWidth + WatchMetrics.iconInset)
        }
        .frame(width: WatchMetrics.ringSize, height: WatchMetrics.ringSize)

        VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing / 2) {
          Text(verbatim: look.detail(of: summary, terms: terms, format: format, now: now))
            .ikaFont(.heavy, size: WatchMetrics.detailSize, relativeTo: .headline)
            // The heavy face's tall line box leaves a gap between wrapped lines, as on Ink's
            // headings.
            .lineHeight(.tight)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
          if let progress = look.progress {
            Text(verbatim: writer.countdown(progress))
              .ikaFont(.light, size: WatchMetrics.countdownSize, relativeTo: .footnote)
              .monospacedDigit()
              .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(.rect)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: summary, at: now))
  }

  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}
