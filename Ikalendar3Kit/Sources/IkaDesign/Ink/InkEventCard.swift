//
//  InkEventCard.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkEventCard

/// Ink's compact card for one event, on a panel: the event's icon and name on a tag in its colour
/// with "Now!" while it runs or "Next" before, what it plays (a Challenge's name, Rule and Stages;
/// a Splatfest's art, title and teams; a Big Run's or an Eggstra Work's Stage and weapons), its
/// times, and its progress while it runs.
///
/// The iPad event strip and the event sheets show it, and so do the Splatfest screen and, while a
/// Splatfest is announced, Regular Battle's screen. It receives `IkaCore` values only and reads no
/// store; the strip wraps it in the action that opens the event's sheet. VoiceOver reads it as one
/// sentence, a Splatfest's with its team names.
public struct InkEventCard: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @TimeSettings private var time

  @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = InkScreenMetrics.eventIconSize

  private let item: EventItem
  private let terms: GameTerms
  private let now: Date

  /// The decoded Splatfest art, or `nil` while there is none.
  @State private var artImage: Image?
  /// The width inside the panel.
  @State private var width: CGFloat = 0

  /// - Parameters:
  ///   - item: The event, a Splatfest with its stored art; its team colours stand alone while
  ///     none is downloaded.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  public init(item: EventItem, terms: GameTerms, now: Date) {
    self.item = item
    self.terms = terms
    self.now = now
  }

  public var body: some View {
    let kind: InkEventKind = .init(item)
    let progress: WindowProgress? = item.isRunning(at: now) ? item.progress(at: now) : nil

    VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
      header(kind, place: progress.map(InkPanelPlace.now) ?? .next)
      content(kind)
      InkTimeTag(Text(verbatim: range))
      if let progress {
        InkProgressBar(
          progress: progress,
          countdown: writer.countdown(progress),
          accent: kind.accent,
          arrangement: arrangement)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onGeometryChange(for: CGFloat.self) { proxy in
      proxy.size.width
    } action: { newWidth in
      width = newWidth
    }
    .inkPanel()
    .task(id: art) {
      artImage = art.flatMap(Image.init(contentsOf:))
    }
    .eventAccessibility(item, writer: writer, at: now)
  }

  // MARK: Header

  /// The event's icon and name tag, and its state tag beside them, or under them when stacked.
  private func header(_ kind: InkEventKind, place: InkPanelPlace) -> some View {
    let layout: AnyLayout =
      switch arrangement {
        case .sideBySide: .init(HStackLayout(spacing: InkScreenMetrics.cardSpacing))
        case .stacked: .init(VStackLayout(alignment: .leading, spacing: InkScreenMetrics.cardSpacing))
      }

    return layout {
      HStack(spacing: InkScreenMetrics.cardSpacing) {
        Image(decorative: BundledImage.name(for: kind.icon, size: .medium), bundle: BundledImage.catalogBundle)
          .resizable()
          .scaledToFit()
          .frame(width: iconSize, height: iconSize)
        InkModeTag(Text(verbatim: kind.label.text(in: terms.language)), accent: kind.accent)
      }
      if arrangement == .sideBySide {
        Spacer(minLength: 0)
      }
      InkStateTag(place: place, accent: kind.accent)
    }
  }

  // MARK: Content

  @ViewBuilder
  private func content(_ kind: InkEventKind) -> some View {
    switch item {
      case .challenge(let window):
        let challenge: Challenge = window.challenge
        InkTitle(text: terms.challenge(challenge.id).name)
        InkRuleLabel(rule: challenge.rule, terms: terms, accent: kind.accent, arrangement: arrangement)
        InkStageRow(stages: challenge.stages, terms: terms, imageSize: .medium, arrangement: arrangement)

      case .splatfest(let card):
        if let artImage {
          artImage
            .resizable()
            .scaledToFit()
            .clipShape(.rect(cornerRadius: InkMetrics.pictureCornerRadius))
        }
        InkTitle(text: terms.splatfest(card.splatfest.id).title)
        InkTeamList(splatfest: card.splatfest, terms: terms)

      case .bigRun(let shift),
           .eggstraWork(let shift):
        InkStageAndWeapons(
          shift: shift,
          terms: terms,
          metrics: CellMetrics(width: width, dynamicTypeSize: dynamicTypeSize))
    }
  }

  // MARK: Parts

  /// A Challenge window's range as a Rotation's, with the weekday since it is announced days
  /// ahead; an event spanning days with each end's date.
  private var range: String {
    switch item {
      case .challenge(let window): format.timeRange(of: window, withWeekday: true)
      case .splatfest,
           .bigRun,
           .eggstraWork: format.dateRange(of: item)
    }
  }

  /// A Splatfest's stored art; the other events have none.
  private var art: URL? {
    guard case .splatfest(let card) = item else { return nil }

    return card.art
  }

  private var arrangement: CellArrangement { dynamicTypeSize.isAccessibilitySize ? .stacked : .sideBySide }

  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - InkEventKind

/// How an event card names its event: the event's label and icon, and its accent. A Splatfest
/// has no Mode colour, so its card is marked in white and its teams' colours sit by their names.
struct InkEventKind: Equatable {
  let label: ModeLabel
  let icon: ModeIcon
  let accent: InkAccent

  /// The kind of `item`.
  init(_ item: EventItem) {
    switch item {
      case .challenge: self.init(label: .challenges, icon: .challenge, accent: InkAccent(.challenge))
      case .splatfest: self.init(label: .splatfest, icon: .splatfestBattle, accent: .splatfest)
      case .bigRun: self.init(label: .bigRun, icon: .bigRun, accent: InkAccent(.bigRun))
      case .eggstraWork: self.init(label: .eggstraWork, icon: .eggstraWork, accent: InkAccent(.eggstraWork))
    }
  }

  init(label: ModeLabel, icon: ModeIcon, accent: InkAccent) {
    self.label = label
    self.icon = icon
    self.accent = accent
  }
}
#endif
