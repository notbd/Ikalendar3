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

/// One Mode's row on the Now page, its summary row (`SummaryRowContent`) in Ink: the Mode's
/// heading across the top, then the summary ring beside the current Rule or the Shift's Stage and
/// the time left; or when the Battle Mode returns from a Splatfest's pause, or that nothing is on.
/// A running Big Run shows as one. The page sets the rows on Ink's dark panel.
///
/// It is one VoiceOver element reading the summary's sentence. It receives `IkaCore` values only.
struct NowRow: View {
  @Environment(\.colorScheme) private var colorScheme
  @TimeSettings private var time

  let summary: ModeSummary
  let terms: GameTerms
  let now: Date

  var body: some View {
    let content: SummaryRowContent = .init(summary, writer: writer, format: time.format(terms.language), now: now)
    let heading: InkModeHeading = .init(summary)
    let accent: InkAccent = .init(content.color)

    VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing) {
      HStack(spacing: WatchMetrics.lineSpacing) {
        Text(verbatim: heading.name.text(in: terms.language))
          .ikaFont(.heavy, size: WatchMetrics.modeNameSize, relativeTo: .footnote)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        if let form = heading.form {
          InkModeTag(Text(verbatim: form.text(in: terms.language)), accent: accent)
        }
      }

      HStack(spacing: WatchMetrics.rowSpacing) {
        SummaryRing(
          content,
          color: Color(accent.base),
          lineWidth: WatchMetrics.ringLineWidth,
          iconInset: WatchMetrics.ringLineWidth + WatchMetrics.iconInset)
          .frame(width: WatchMetrics.ringSize, height: WatchMetrics.ringSize)

        VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing / 2) {
          Text(verbatim: content.detail)
            .ikaFont(.heavy, size: WatchMetrics.detailSize, relativeTo: .headline)
            // The heavy face's tall line box leaves a gap between wrapped lines, as on Ink's
            // headings.
            .lineHeight(.tight)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
          if let progress = content.progress {
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
    .accessibilityLabel(content.accessibilityLabel)
  }

  private var writer: SentenceWriter { time.writer(terms) }
}
