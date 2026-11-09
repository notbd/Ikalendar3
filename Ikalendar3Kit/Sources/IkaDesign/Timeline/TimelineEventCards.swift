//
//  TimelineEventCards.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineEventCard

/// Timeline's compact card of an event the iPad event strip and the event sheets show: a
/// Challenge window, a Splatfest, a Big Run or an Eggstra Work, on Timeline's panel with "Now"
/// and the countdown while it runs. VoiceOver reads it as one sentence. It receives `IkaCore`
/// values only and reads no store; the caller sets its width.
public struct TimelineEventCard: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @TimeSettings private var time

  private let item: EventItem
  private let art: URL?
  private let terms: GameTerms
  private let now: Date

  /// - Parameters:
  ///   - item: The event.
  ///   - art: A Splatfest's stored art file from the screen value, or `nil` while none is
  ///     downloaded: the team colours stand alone then. Other events ignore it.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  public init(item: EventItem, art: URL?, terms: GameTerms, now: Date) {
    self.item = item
    self.art = art
    self.terms = terms
    self.now = now
  }

  public var body: some View {
    let arrangement: CellArrangement = .init(dynamicTypeSize)
    let format: TimelineFormat = time.timelineFormat(terms.language)
    let progress: WindowProgress? = item.isRunning(at: now) ? item.progress(at: now) : nil

    switch item {
      case .challenge(let window):
        TimelineCardPanel {
          VStack(alignment: .leading, spacing: 8) {
            TimelineHeadline(arrangement: arrangement) {
              TimelineModeTag(
                icon: .challenge,
                label: ModeLabel.challenges.text(in: terms.language),
                colors: ModeColor.challenge.asFill)
            } trailing: {
              if let progress {
                TimelineNowTag(
                  timeLeft: progress.timeLeft,
                  color: TimelineTint(.challenge),
                  language: terms.language,
                  now: now)
              }
            }
            TimelineChallengeTitle(challenge: window.challenge, terms: terms)
            Text(verbatim: format.timeRange(from: window.startTime, to: window.endTime))
              .ikaFont(.light, size: 14, relativeTo: .subheadline)
              .foregroundStyle(.white)
              .fixedSize(horizontal: false, vertical: true)
            TimelineRuleLabel(rule: window.challenge.rule, terms: terms, arrangement: arrangement)
            TimelineStageStrip(stages: window.challenge.stages, terms: terms, arrangement: arrangement)
          }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(writer.sentence(for: item, at: now))

      case .splatfest(let splatfest):
        TimelineSplatfestCard(splatfest: splatfest, art: art, terms: terms, now: now)

      case .bigRun(let shift),
           .eggstraWork(let shift):
        TimelineCardPanel {
          TimelineShiftContent(
            shift: shift,
            progress: progress,
            terms: terms,
            format: format,
            now: now,
            arrangement: arrangement)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(writer.sentence(for: item, at: now))
    }
  }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - TimelineSplatfestCard

/// Timeline's Splatfest card, on the Splatfest screen, on Regular Battle's screen while the
/// Splatfest is announced and in the event strip: the art once downloaded, else a band of the
/// team colours, then the title, the three teams with their names in their colours, the dates
/// and, while it runs, "Now" with the countdown. VoiceOver reads it as one sentence with the
/// team names as its value.
struct TimelineSplatfestCard: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @TimeSettings private var time

  let splatfest: Splatfest
  /// The stored art file, or `nil` while none is downloaded.
  let art: URL?
  let terms: GameTerms
  let now: Date

  /// The decoded art, or `nil` while there is none.
  @State private var artImage: Image?

  var body: some View {
    let texts = terms.splatfest(splatfest.id)
    // Looked up one by one: the source may lack them.
    let teamNames: [String] = texts.teamNames ?? []
    let format: TimelineFormat = time.timelineFormat(terms.language)

    TimelineCardPanel(inset: false) {
      VStack(alignment: .leading, spacing: 0) {
        artOrTeamBand
        VStack(alignment: .leading, spacing: 8) {
          TimelineHeadline(arrangement: CellArrangement(dynamicTypeSize)) {
            TimelineModeTag(
              icon: .splatfestBattle,
              label: ModeLabel.splatfest.text(in: terms.language),
              colors: TimelinePalette.idlePin)
          } trailing: {
            if splatfest.isRunning(at: now) {
              TimelineNowTag(
                timeLeft: splatfest.progress(at: now).timeLeft,
                color: .neutral,
                language: terms.language,
                now: now)
            }
          }
          Text(verbatim: texts.title)
            .ikaFont(.heavy, size: 18, relativeTo: .headline)
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
          ForEach(splatfest.teamColors.indices, id: \.self) { index in
            if teamNames.indices.contains(index) {
              team(named: teamNames[index], color: SRGBColor(splatfest.teamColors[index]))
            }
          }
          Text(verbatim: format.dateRange(from: splatfest.startTime, to: splatfest.endTime))
            .ikaFont(.light, size: 13, relativeTo: .footnote)
            .foregroundStyle(TimelinePalette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(TimelineMetrics.cardPadding)
      }
    }
    .task(id: art) {
      artImage = art.flatMap(Image.init(contentsOf:))
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(time.writer(terms)
      .sentence(for: splatfest, at: now))
    .accessibilityValue(teamNames.formatted(.list(type: .and).locale(Locale(identifier: terms.language.rawValue))))
  }

  /// The art, or the team colours side by side while it is not downloaded.
  @ViewBuilder private var artOrTeamBand: some View {
    if let artImage {
      artImage
        .resizable()
        .scaledToFit()
    }
    else {
      HStack(spacing: 0) {
        ForEach(splatfest.teamColors.indices, id: \.self) { index in
          Color(SRGBColor(splatfest.teamColors[index]))
        }
      }
      .frame(height: TimelineMetrics.teamBandHeight)
    }
  }

  /// A team's swatch and its name in its colour, tinted to read on Timeline's panel.
  private func team(named name: String, color: SRGBColor) -> some View {
    HStack(spacing: 8) {
      Circle()
        .fill(Color(color))
        .frame(width: TimelineMetrics.teamSwatchSize, height: TimelineMetrics.teamSwatchSize)
      Text(verbatim: name)
        .ikaFont(.heavy, size: 15, relativeTo: .subheadline)
        .foregroundStyle(Color(color.readableTint(on: Style.timeline.panel(in: colorScheme), for: .text)))
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

// MARK: - TimelineChallengeTitle

/// A Challenge's name.
struct TimelineChallengeTitle: View {
  let challenge: Challenge
  let terms: GameTerms

  var body: some View {
    Text(verbatim: terms.challenge(challenge.id).name)
      .ikaFont(.heavy, size: 20, relativeTo: .title3)
      .foregroundStyle(.white)
      .fixedSize(horizontal: false, vertical: true)
  }
}

// MARK: - TimelineCardPanel

/// A card on Timeline's panel colour, the background team names and Mode colours are tinted to
/// read on, with rounded corners.
struct TimelineCardPanel<Content: View>: View {
  @Environment(\.colorScheme) private var colorScheme

  /// Whether the content sits inside the card's padding; a card whose art runs to the edges
  /// pads its own text.
  var inset = true
  @ViewBuilder let content: Content

  var body: some View {
    content
      .padding(inset ? TimelineMetrics.cardPadding : 0)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color(Style.timeline.panel(in: colorScheme)))
      .clipShape(.rect(cornerRadius: TimelineMetrics.pictureCornerRadius))
  }
}
#endif
