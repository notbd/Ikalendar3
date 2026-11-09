//
//  InkPanelParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkStateTag

/// A panel's state tag, turned like a sticker: "Now!" in the Mode's colour on the featured panel,
/// "Next" in the game's purple on the next one, and none on later panels.
struct InkStateTag: View {
  @Environment(\.gameLanguage) private var language
  @Environment(\.colorScheme) private var colorScheme

  let place: InkPanelPlace
  /// The colour of "Now!": the Mode's, the Shift kind's, or a Splatfest's white.
  let accent: InkAccent

  var body: some View {
    Group {
      switch place {
        case .now:
          InkModeTag(Text(verbatim: InkText.now.text(in: language)), accent: accent)

        case .next:
          InkTagLabel(
            text: Text(verbatim: InkText.next.text(in: language)),
            style: .tag,
            colors: InkPair.nextTagText.colors(in: colorScheme))

        case .later:
          EmptyView()
      }
    }
    .rotationEffect(InkScreenMetrics.stateTagAngle)
  }
}

// MARK: - InkPanelHeader

/// A panel's top row: its time tag on the leading side, its tags on the trailing side. From the
/// first accessibility text size the tags go under the time, so neither shrinks.
struct InkPanelHeader<Tags: View>: View {
  let timeRange: String
  let arrangement: CellArrangement
  @ViewBuilder let tags: Tags

  var body: some View {
    switch arrangement {
      case .sideBySide:
        HStack(spacing: InkScreenMetrics.cardSpacing) {
          InkTimeTag(Text(verbatim: timeRange))
          Spacer(minLength: 0)
          tags
        }

      case .stacked:
        VStack(alignment: .leading, spacing: InkScreenMetrics.cardSpacing) {
          InkTimeTag(Text(verbatim: timeRange))
          HStack(spacing: InkScreenMetrics.cardSpacing) { tags }
        }
    }
  }
}

// MARK: - InkProgressBar

/// The featured panel's progress: a skewed bar filling in the accent, and the countdown
/// beside it (under it from the first accessibility text size), ticking on whole seconds.
/// VoiceOver reads the time left in the panel's sentence instead.
struct InkProgressBar: View {
  @Environment(\.colorScheme) private var colorScheme

  let progress: WindowProgress
  let countdown: String
  let accent: InkAccent
  let arrangement: CellArrangement

  var body: some View {
    let layout: AnyLayout =
      switch arrangement {
        case .sideBySide: .init(HStackLayout(spacing: InkScreenMetrics.panelRowSpacing))
        case .stacked: .init(VStackLayout(alignment: .trailing, spacing: InkScreenMetrics.panelRowSpacing / 2))
      }

    layout {
      bar
      Text(verbatim: countdown)
        .inkFont(.caption)
        .monospacedDigit()
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
        .scaledLimitedLine(for: arrangement)
        .countdownRoll(value: countdown)
        .layoutPriority(1)
    }
  }

  private var bar: some View {
    let plate: SkewedRectangle = .init(slant: InkScreenMetrics.progressBarSlant)
    let geometry: ProgressBarGeometry = .init(share: progress.sharePassed)

    return plate
      .fill(InkDecoration.progressTrack)
      .overlay(alignment: .leading) {
        GeometryReader { proxy in
          plate
            .fill(Color(accent.base))
            .frame(width: geometry.fillWidth(in: proxy.size.width))
        }
      }
      .frame(height: InkScreenMetrics.progressBarHeight)
      .frame(maxWidth: .infinity)
  }
}
#endif
