//
//  ClassicSplatfestCells.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicSplatfestCard

/// Classic's Splatfest card, on the Splatfest screen and on Regular Battle's screen while a
/// Splatfest is announced: the art once downloaded, the Splatfest icon and title, the three teams
/// in their colours with their names, the times and, while it runs, its progress.
struct ClassicSplatfestCard: View {
  typealias Scoped = ClassicMetrics.Splatfest

  @TimeSettings private var time

  @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = Scoped.iconSize

  let splatfest: Splatfest
  /// Its stored art, or `nil` while none is downloaded: the team colours stand alone then.
  let art: URL?
  let terms: GameTerms
  let now: Date
  let metrics: CellMetrics

  var body: some View {
    VStack(alignment: .leading, spacing: Scoped.cellSpacingV) {
      ClassicSplatfestArt(art: art)

      HStack(spacing: ClassicMetrics.Header.tagPaddingH) {
        ClassicSplatfestIcon()
          .frame(width: iconSize, height: iconSize)
        Text(verbatim: terms.splatfest(splatfest.id).title)
          .fixedSize(horizontal: false, vertical: true)
          .ikaFont(.heavy, size: Scoped.titleFontSize, relativeTo: .title2)
      }

      ClassicTeamList(splatfest: splatfest, terms: terms, arrangement: metrics.arrangement)

      Text(verbatim: timeFormat.range(of: splatfest, now: now))
        .scaledLimitedLine(for: metrics.arrangement)
        .foregroundStyle(.secondary)
        .ikaFont(.light, size: Scoped.timeFontSize, relativeTo: .subheadline)

      if splatfest.isRunning(at: now) {
        ClassicProgressBar(
          progress: splatfest.progress(at: now),
          tint: .primary,
          terms: terms,
          now: now,
          arrangement: metrics.arrangement)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, Scoped.cellPaddingV)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(time.writer(terms).sentence(for: splatfest, at: now))
    .accessibilityValue(ClassicTeamList.names(of: splatfest, terms: terms))
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }
}

// MARK: - ClassicSplatfestArt

/// A Splatfest's stored art on glass, or nothing while none is downloaded or it does not decode.
/// Decorative: the card's sentence names the Splatfest.
struct ClassicSplatfestArt: View {
  let art: URL?

  @State private var image: Image?

  var body: some View {
    Group {
      if let image {
        image
          .resizable()
          .scaledToFit()
          .clipShape(.rect(cornerRadius: ClassicMetrics.Splatfest.artCornerRadius))
          .adaptiveGlassEffect(in: .rect(cornerRadius: ClassicMetrics.Splatfest.artCornerRadius))
          .shadow(radius: ClassicMetrics.shadowRadius)
          .accessibilityHidden(true)
      }
    }
    .task(id: art) {
      image = art.flatMap(Image.init(contentsOf:))
    }
  }
}

// MARK: - ClassicSplatfestIcon

/// The Splatfest's icon: Splatfest Battle's Mode icon stands in until ticket 53 draws one.
struct ClassicSplatfestIcon: View {
  var body: some View {
    ClassicPicture(name: BundledImage.name(for: ModeIcon.splatfestBattle, size: .medium))
      .shadow(radius: ClassicMetrics.shadowRadius)
  }
}

// MARK: - ClassicTeamList

/// A Splatfest's three teams, each a swatch of its feed colour beside its name, which is drawn in
/// that colour tinted at run time until it reads at 4.5:1 on Classic's panel. A team colour never
/// shows without its name, unless the terms lack the names.
struct ClassicTeamList: View {
  typealias Scoped = ClassicMetrics.Splatfest

  @Environment(\.colorScheme) private var colorScheme

  @ScaledMetric(relativeTo: .headline) private var swatchSize: CGFloat = Scoped.teamSwatchSize

  let splatfest: Splatfest
  let terms: GameTerms
  let arrangement: CellArrangement

  var body: some View {
    // The terms may lack the names, so each is looked up by position.
    let names: [String] = terms.splatfest(splatfest.id).teamNames ?? []

    VStack(alignment: .leading, spacing: Scoped.teamSpacingV) {
      ForEach(splatfest.teamColors.indices, id: \.self) { index in
        let color: SRGBColor = .init(splatfest.teamColors[index])

        HStack(spacing: ClassicMetrics.Header.tagPaddingH) {
          Circle()
            .fill(Color(color))
            .overlay(Circle().strokeBorder(.primary.opacity(0.25), lineWidth: 1))
            .frame(width: swatchSize, height: swatchSize)
          if names.indices.contains(index) {
            Text(verbatim: names[index])
              .scaledLimitedLine(for: arrangement)
              .foregroundStyle(Color(color.readableTint(on: Style.classic.panel(in: colorScheme), for: .text)))
              .ikaFont(.heavy, size: Scoped.teamFontSize, relativeTo: .headline)
          }
        }
      }
    }
  }

  /// The team names as the text set lists them, which a card's VoiceOver value reads.
  static func names(of splatfest: Splatfest, terms: GameTerms) -> String {
    (terms.splatfest(splatfest.id).teamNames ?? [])
      .formatted(.list(type: .and).locale(Locale(identifier: terms.language.rawValue)))
  }
}

// MARK: - ClassicTricolorSection

/// Tricolor Turf War in the Splatfest's second half: a header with its name and time range over
/// its Stages, drawn as the current Rotation's are, and its progress bar.
struct ClassicTricolorSection: View {
  typealias Scoped = ClassicMetrics.BattlePrimary

  @TimeSettings private var time

  let tricolor: Running<TricolorTurfWar>
  let terms: GameTerms
  let now: Date
  let metrics: CellMetrics

  var body: some View {
    Section {
      VStack(alignment: .leading, spacing: Scoped.cellSpacingV) {
        let stages: AnyLayout = metrics.arrangement == .stacked
          ? AnyLayout(VStackLayout(spacing: Scoped.stagesSpacingH))
          : AnyLayout(HStackLayout(spacing: Scoped.stagesSpacingH))
        stages {
          ForEach(tricolor.item.stages, id: \.self) { stage in
            ClassicBattleStageCard(
              stage: stage,
              name: terms.name(of: stage),
              role: .primary,
              arrangement: metrics.arrangement)
          }
        }

        ClassicProgressBar(
          progress: tricolor.progress,
          tint: .primary,
          terms: terms,
          now: now,
          arrangement: metrics.arrangement)
      }
      .padding(.bottom, Scoped.cellPaddingBottom)
      .accessibilityElement(children: .combine)
    } header: {
      let layout: AnyLayout = metrics.arrangement == .stacked
        ? AnyLayout(VStackLayout(alignment: .leading))
        : AnyLayout(HStackLayout(spacing: ClassicMetrics.Header.spacing))

      layout {
        ClassicTag(text: ModeLabel.tricolor.text(in: terms.language))
        Text(verbatim: timeFormat.battleRange(from: tricolor.item.startTime, to: tricolor.item.endTime, now: now))
          .scaledLimitedLine(for: metrics.arrangement)
          .ikaFont(.light, size: ClassicMetrics.Header.contentFontSize, relativeTo: .headline)
      }
      .accessibilityElement(children: .combine)
    }
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }
}

// MARK: - ClassicProgressBar

/// A running window's progress bar with its time left above the trailing end, as a running
/// Shift shows it. The time left is a text of its own rather than the bar's label, which keeps
/// it to the bar's height and truncates it at the largest text sizes.
struct ClassicProgressBar: View {
  let progress: WindowProgress
  let tint: Color
  let terms: GameTerms
  let now: Date
  let arrangement: CellArrangement

  @TimeSettings private var time

  var body: some View {
    VStack(alignment: .trailing, spacing: ClassicMetrics.Header.progressSpacing) {
      Text(verbatim: ClassicText.timeLeft.text(in: terms.language, timeFormat.span(progress.timeLeft)))
        .countdownRoll(value: now)
        .scaledLimitedLine(for: arrangement)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(.secondary)
        .ikaFont(.light, size: ClassicMetrics.BattlePrimary.remainingTimeFontSize, relativeTo: .headline)
      ProgressView(value: progress.sharePassed)
        .tint(tint)
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }
}

// MARK: - ClassicTimeFormat

extension ClassicTimeFormat {
  /// A window spanning days, such as a Splatfest's or a Shift's: each end with its day.
  func range(of window: some TimeWindow, now: Date) -> String {
    "\(shiftTime(window.startTime, now: now)) - \(shiftTime(window.endTime, now: now))"
  }
}
#endif
