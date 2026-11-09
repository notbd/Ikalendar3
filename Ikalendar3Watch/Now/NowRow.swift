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
    let look: Look = .init(summary)
    let heading = look.heading

    VStack(alignment: .leading, spacing: NowMetrics.lineSpacing) {
      HStack(spacing: NowMetrics.lineSpacing) {
        Text(verbatim: heading.name.text(in: terms.language))
          .ikaFont(.heavy, size: NowMetrics.modeNameSize, relativeTo: .footnote)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        if let form = heading.form {
          InkModeTag(Text(verbatim: form.text(in: terms.language)), modeColor: look.color)
        }
      }

      HStack(spacing: NowMetrics.rowSpacing) {
        ZStack {
          ProgressRing(share: look.share, color: Color(look.color.base), lineWidth: NowMetrics.ringLineWidth)
          Image(decorative: BundledImage.name(for: look.icon, size: .small), bundle: BundledImage.catalogBundle)
            .resizable()
            .scaledToFit()
            .padding(NowMetrics.ringLineWidth + NowMetrics.iconInset)
        }
        .frame(width: NowMetrics.ringSize, height: NowMetrics.ringSize)

        VStack(alignment: .leading, spacing: NowMetrics.lineSpacing / 2) {
          Text(verbatim: detail)
            .ikaFont(.heavy, size: NowMetrics.detailSize, relativeTo: .headline)
            // The heavy face's tall line box leaves a gap between wrapped lines, as on Ink's
            // headings.
            .lineHeight(.tight)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
          if let progress = look.progress {
            Text(verbatim: writer.countdown(progress))
              .ikaFont(.light, size: NowMetrics.countdownSize, relativeTo: .footnote)
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

  /// The current Rule or Shift Stage, when the Battle Mode returns, or that nothing is on.
  private var detail: String {
    switch summary {
      case .battle(_, .running(let running)),
           .splatfestBattle(_, .running(let running)):
        // A summary's Rotation always plays: a paused window reads as the pause instead.
        running.item.setting.map { terms.name(of: $0.rule) } ?? ""
      case .salmonRun(.running(let running)):
        terms.name(of: running.item.stage)
      case .battle(_, .paused(let returnTime)),
           .splatfestBattle(_, .paused(let returnTime)),
           .salmonRun(.paused(let returnTime)):
        ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: now))
      case .battle(_, .nothingCurrent),
           .splatfestBattle(_, .nothingCurrent),
           .salmonRun(.nothingCurrent):
        ScreenText.nothingCurrent.text(in: terms.language)
    }
  }

  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: NowRow.Look

extension NowRow {
  /// What a row draws for its summary besides the text: the icon, colour and heading of the Mode
  /// or of the Shift kind on, and how far the current item has run.
  struct Look {
    let icon: ModeIcon
    let color: ModeColor
    let heading: InkModeHeading
    /// The current item's progress, or `nil` while none is on.
    let progress: WindowProgress?

    init(_ summary: ModeSummary) {
      switch summary {
        case .battle(let mode, let current):
          icon = ModeIcon(Mode.battle(mode))
          color = ModeColor(mode)
          heading = InkModeHeading(.battle(mode))
          progress = Self.progress(of: current)

        case .splatfestBattle(let form, let current):
          // The Now page lists Modes only and shows a Splatfest as its teams on top. Splatfest
          // Battle has no colour of its own, so it takes Regular Battle's, whose place it takes.
          icon = ModeIcon(RotationMode.splatfestBattle(form))
          color = ModeColor.regularBattle
          heading = InkModeHeading(splatfestBattle: form)
          progress = Self.progress(of: current)

        case .salmonRun(.running(let running)):
          icon = ModeIcon(running.item.kind)
          color = ModeColor(running.item.kind)
          heading = InkModeHeading(name: ModeLabel(running.item.kind), form: nil)
          progress = running.progress

        case .salmonRun(let current):
          icon = ModeIcon(Mode.salmonRun)
          color = ModeColor.salmonRun
          heading = InkModeHeading(.salmonRun)
          progress = Self.progress(of: current)
      }
    }

    /// The share of the ring drawn: what the current item has run, or none.
    var share: Double {
      progress?.sharePassed ?? 0
    }

    static private func progress(of current: OnNow<some TimeWindow & Hashable & Sendable>) -> WindowProgress? {
      if case .running(let running) = current { running.progress } else { nil }
    }
  }
}
