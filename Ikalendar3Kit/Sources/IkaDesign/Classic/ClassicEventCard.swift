//
//  ClassicEventCard.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicEventCard

/// Classic's compact card for one event of the iPad event strip and the event sheets: the
/// event's Mode icon and name tag, what it plays (a Challenge's name, Rule and Stages; a
/// Splatfest's art, title and teams; a Big Run's or an Eggstra Work's Stage and weapons), its
/// times, and its progress while it runs or a countdown to its start.
///
/// It receives `IkaCore` values only and reads no store; the strip wraps it in the action that
/// opens the event's sheet. VoiceOver reads it as one sentence.
public struct ClassicEventCard: View {
  typealias Scoped = ClassicMetrics.EventCard

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @TimeSettings private var time

  @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = Scoped.iconSize
  @ScaledMetric(relativeTo: .body) private var ruleIconSize: CGFloat = Scoped.ruleIconSize

  private let item: EventItem
  private let terms: GameTerms
  private let now: Date

  /// - Parameters:
  ///   - item: The event, a Splatfest with its stored art.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  public init(item: EventItem, terms: GameTerms, now: Date) {
    self.item = item
    self.terms = terms
    self.now = now
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: Scoped.spacing) {
      header
      content
      times
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Scoped.padding)
    .background(Self.background, in: .rect(cornerRadius: Scoped.cornerRadius))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(sentence)
    .accessibilityValue(value)
  }

  // MARK: Header

  private var header: some View {
    HStack(spacing: Scoped.spacing) {
      Group {
        if case .splatfest = item {
          ClassicSplatfestIcon()
        }
        else {
          ClassicPicture(name: BundledImage.name(for: kind.icon, size: .medium))
            .shadow(radius: ClassicMetrics.shadowRadius)
        }
      }
      .frame(width: iconSize, height: iconSize)

      let name: String = kind.label.text(in: terms.language)
      if let color = kind.color {
        ClassicKindTag(text: name, color: color)
      }
      else {
        ClassicTag(text: name)
      }
    }
  }

  // MARK: Content

  @ViewBuilder private var content: some View {
    switch item {
      case .challenge(let window):
        Text(verbatim: terms.challenge(window.challenge.id).name)
          .scaledLimitedLine(for: arrangement)
          .ikaFont(.heavy, size: Scoped.titleFontSize, relativeTo: .title3)
        HStack(spacing: Scoped.spacing) {
          ClassicPicture(name: BundledImage.name(for: window.challenge.rule, size: .medium))
            .frame(width: ruleIconSize, height: ruleIconSize)
          Text(verbatim: terms.name(of: window.challenge.rule))
            .scaledLimitedLine(for: arrangement)
            .ikaFont(.light, size: Scoped.detailFontSize, relativeTo: .body)
        }
        stages(window.challenge.stages)

      case .splatfest(let card):
        ClassicSplatfestArt(art: card.art)
        Text(verbatim: terms.splatfest(card.splatfest.id).title)
          .fixedSize(horizontal: false, vertical: true)
          .ikaFont(.heavy, size: Scoped.titleFontSize, relativeTo: .title3)
        ClassicTeamList(splatfest: card.splatfest, terms: terms, arrangement: arrangement)

      case .bigRun(let shift),
           .eggstraWork(let shift):
        ClassicShiftStageCard(
          stage: shift.stage,
          stageName: terms.name(of: shift.stage),
          kingSalmonid: shift.kingSalmonid,
          isRunning: shift.isRunning(at: now),
          arrangement: arrangement)
        ClassicWeaponsCard(weapons: shift.weapons, terms: terms, columnCount: 4)
    }
  }

  /// A Challenge's Stages beside each other with their names under them, or stacked.
  private func stages(_ stages: [StageID]) -> some View {
    let layout: AnyLayout = arrangement == .stacked
      ? AnyLayout(VStackLayout(spacing: Scoped.spacing))
      : AnyLayout(HStackLayout(alignment: .top, spacing: Scoped.spacing))

    return layout {
      ForEach(stages, id: \.self) { stage in
        ClassicBattleStageCard(stage: stage, name: terms.name(of: stage), role: .secondary, arrangement: arrangement)
      }
    }
  }

  // MARK: Times

  /// The event's times, then its progress while it runs or a countdown to its start.
  @ViewBuilder private var times: some View {
    Text(verbatim: range)
      .scaledLimitedLine(for: arrangement)
      .ikaFont(.light, size: Scoped.detailFontSize, relativeTo: .headline)

    if item.isRunning(at: now) {
      ClassicProgressBar(
        progress: item.progress(at: now),
        tint: kind.color?.classicTint(in: colorScheme) ?? .primary,
        terms: terms,
        now: now,
        arrangement: arrangement)
    }
    else if now < item.startTime {
      Text(verbatim: ClassicText.timeUntil.text(
        in: terms.language,
        timeFormat.span(.seconds(item.startTime.timeIntervalSince(now)))))
        .countdownRoll(value: now)
        .scaledLimitedLine(for: arrangement)
        .foregroundStyle(.secondary)
        .ikaFont(.light, size: ClassicMetrics.BattlePrimary.remainingTimeFontSize, relativeTo: .headline)
    }
  }

  /// A Challenge window's range as a Rotation's, an event spanning days with each end's day.
  private var range: String {
    switch item {
      case .challenge(let window): timeFormat.battleRange(from: window.startTime, to: window.endTime, now: now)
      case .splatfest,
           .bigRun,
           .eggstraWork: timeFormat.range(of: item, now: now)
    }
  }

  // MARK: Kind

  /// The event's Mode icon, its name and its Mode colour; a Splatfest has no Mode colour, its
  /// teams' colours stand for it.
  private var kind: (icon: ModeIcon, label: ModeLabel, color: ModeColor?) {
    switch item {
      case .challenge: (.challenge, .challenges, .challenge)
      case .splatfest: (.splatfestBattle, .splatfest, nil)
      case .bigRun: (.bigRun, .bigRun, .bigRun)
      case .eggstraWork: (.eggstraWork, .eggstraWork, .eggstraWork)
    }
  }

  // MARK: Accessibility

  private var sentence: String {
    switch item {
      case .challenge(let window): writer.sentence(for: window, at: now)
      case .splatfest(let card): writer.sentence(for: card.splatfest, at: now)
      case .bigRun(let shift),
           .eggstraWork(let shift): writer.sentence(for: shift, at: now)
    }
  }

  /// A Splatfest's team names; the other events' sentences say all.
  private var value: String {
    if case .splatfest(let card) = item { ClassicTeamList.names(of: card.splatfest, terms: terms) } else { "" }
  }

  // MARK: Parts

  private var arrangement: CellArrangement { CellArrangement(dynamicTypeSize) }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }

  private var writer: SentenceWriter { time.writer(terms) }

  /// A Classic list cell's colour, so a card reads as one of its cells.
  static private var background: Color {
    #if os(iOS)
    Color(uiColor: .secondarySystemGroupedBackground)
    #else
    Color(nsColor: .controlBackgroundColor)
    #endif
  }
}
#endif
