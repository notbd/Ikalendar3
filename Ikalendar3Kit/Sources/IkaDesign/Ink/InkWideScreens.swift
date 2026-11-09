//
//  InkWideScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkWideBattleScreenView

/// Ink's wide Battle Mode detail on iPad and Mac: the Mode's heading and stamp over the dotted
/// background as on iPhone, then, in a centred column, the current Rotation's taped panel as one
/// wide row (state and time tags, Rule, progress ring and countdown beside both Stages) and one
/// panel holding every later Rotation as a table row.
///
/// It receives `IkaCore` values only and reads no store.
public struct InkWideBattleScreenView: View {
  @TimeSettings private var time

  private let screen: BattleScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool
  private let wide: WideDetailMetrics

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  ///   - wide: The wide detail's column.
  public init(screen: BattleScreen, terms: GameTerms, now: Date, isStale: Bool, wide: WideDetailMetrics) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
    self.wide = wide
  }

  public var body: some View {
    let entries: [InkPanelEntry<Rotation>] = InkPanelEntry.entries(
      current: screen.current,
      next: screen.next,
      later: screen.later)
    let mode: Mode = .battle(screen.mode)
    let accent: InkAccent = .init(ModeColor(mode))

    InkScheduleList(
      heading: InkModeHeading(mode),
      icon: ModeIcon(mode),
      accent: accent,
      title: screen.mode.name(in: terms.language),
      reflowValue: entries.map(\.id),
      fetchTime: screen.fetchTime,
      now: now,
      isStale: isStale)
    { _ in
      if let card = screen.announcedSplatfest {
        InkEventCard(item: .splatfest(card.splatfest), art: card.art, terms: terms, now: now)
      }
      switch screen.current {
        case .running:
          EmptyView()
        case .paused(let returnTime):
          InkNote(text: ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: now)))
        case .nothingCurrent:
          InkNote(text: ScreenText.nothingCurrent.text(in: terms.language))
      }
      // A lineup's Rotations always play: a paused window is never an item.
      ForEach(entries.filter { $0.place.progress != nil }) { entry in
        if let setting = entry.item.setting, let progress = entry.place.progress {
          InkWideRow {
            InkWideTags(timeRange: format.timeRange(of: entry.item)) {
              InkStateTag(place: entry.place, accent: accent)
            }
            InkWideRule(rule: setting.rule, accent: accent, style: .headline, terms: terms)
              .frame(height: wide.half.length(InkScreenMetrics.ruleIconHeight))
            InkWideProgress(progress: progress, accent: accent, writer: writer, wide: wide)
          } trailing: {
            HStack(alignment: .top, spacing: InkScreenMetrics.cardSpacing) {
              ForEach(Array(setting.stages.enumerated()), id: \.offset) { _, stage in
                InkStageCard(stage: stage, name: Text(verbatim: terms.name(of: stage)), imageSize: .large)
              }
            }
          }
          .inkPanel(isTaped: true)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(writer.sentence(for: entry.item, at: now))
        }
      }
      InkTablePanel(entries: entries.filter { $0.place.progress == nil }) { entry in
        if let setting = entry.item.setting {
          WideTableColumns(wide: wide, spacing: InkScreenMetrics.cardSpacing) {
            InkWideTags(timeRange: format.timeRange(of: entry.item)) {
              InkStateTag(place: entry.place, accent: accent)
            }
          } middle: {
            InkWideRule(rule: setting.rule, accent: accent, style: .label, terms: terms)
              .frame(height: wide.half.length(.tableRuleIconHeight))
          } trailing: {
            ForEach(Array(setting.stages.enumerated()), id: \.offset) { _, stage in
              InkStageCard(stage: stage, name: Text(verbatim: terms.name(of: stage)), imageSize: .medium)
                .frame(width: wide.half.length(.tableThumbnailWidth))
            }
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(writer.sentence(for: entry.item, at: now))
        }
      }
    }
    .contentMargins(.horizontal, wide.sideMargin, for: .scrollContent)
  }

  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - InkWideSalmonRunScreenView

/// Ink's wide Salmon Run detail on iPad and Mac: the Mode's heading and stamp as on iPhone, then,
/// in a centred column, each running Shift's taped panel as one wide row (tags, time, King
/// Salmonid, progress ring and countdown beside the Stage and the four weapons) and one panel
/// holding every other Shift, a running or announced Eggstra Work on top as on iPhone.
///
/// It receives `IkaCore` values only and reads no store.
public struct InkWideSalmonRunScreenView: View {
  @TimeSettings private var time
  @Environment(\.gameLanguage) private var language

  private let screen: SalmonRunScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool
  private let wide: WideDetailMetrics

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  ///   - wide: The wide detail's column.
  public init(screen: SalmonRunScreen, terms: GameTerms, now: Date, isStale: Bool, wide: WideDetailMetrics) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
    self.wide = wide
  }

  public var body: some View {
    let eggstraWork: [InkPanelEntry<Shift>] =
      if let running = screen.eggstraWork { [InkPanelEntry(item: running.item, place: .now(running.progress))] }
      else if let next = screen.nextEggstraWork { [InkPanelEntry(item: next, place: .next)] }
      else { [] }
    let entries: [InkPanelEntry<Shift>] = eggstraWork + InkPanelEntry.entries(
      current: screen.current,
      next: screen.next,
      later: screen.later)

    InkScheduleList(
      heading: InkModeHeading(.salmonRun),
      icon: .salmonRun,
      accent: InkAccent(.salmonRun),
      title: Mode.salmonRun.name(in: terms.language),
      reflowValue: entries.map(\.id),
      fetchTime: screen.fetchTime,
      now: now,
      isStale: isStale)
    { _ in
      switch screen.current {
        case .running:
          EmptyView()
        case .paused,
             .nothingCurrent:
          InkNote(text: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach(entries.filter { $0.place.progress != nil }) { entry in
        if let progress = entry.place.progress {
          featured(entry.item, place: entry.place, progress: progress)
        }
      }
      InkTablePanel(entries: entries.filter { $0.place.progress == nil }) { entry in
        let shift: Shift = entry.item

        WideTableColumns(wide: wide, spacing: InkScreenMetrics.cardSpacing) {
          tags(of: entry)
        } middle: {
          InkStageCard(stage: shift.stage, name: Text(verbatim: terms.name(of: shift.stage)), imageSize: .medium)
            .frame(width: wide.half.length(.tableThumbnailWidth))
        } trailing: {
          InkWeapons(weapons: shift.weapons, terms: terms, columns: shift.weapons.count)
            .frame(width: wide.half.length(.tableWeaponSize) * CGFloat(shift.weapons.count))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(writer.sentence(for: shift, at: now))
      }
    }
    .contentMargins(.horizontal, wide.sideMargin, for: .scrollContent)
  }

  private func featured(_ shift: Shift, place: InkPanelPlace, progress: WindowProgress) -> some View {
    InkWideRow {
      tags(of: InkPanelEntry(item: shift, place: place))
      if let kingSalmonid = shift.kingSalmonid {
        InkKingSalmonidRow(kingSalmonid: kingSalmonid, terms: terms, arrangement: .sideBySide)
      }
      InkWideProgress(progress: progress, accent: InkAccent(ModeColor(shift.kind)), writer: writer, wide: wide)
    } trailing: {
      HStack(alignment: .top, spacing: InkScreenMetrics.cardSpacing) {
        InkStageCard(stage: shift.stage, name: Text(verbatim: terms.name(of: shift.stage)), imageSize: .large)
        InkWeapons(weapons: shift.weapons, terms: terms, columns: 2)
          .frame(width: wide.half.length(InkScreenMetrics.weaponsWidth))
      }
    }
    .inkPanel(isTaped: true)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: shift, at: now))
  }

  /// A Shift's kind and state tags, and its time range with the weekday.
  private func tags(of entry: InkPanelEntry<Shift>) -> some View {
    let accent: InkAccent = .init(ModeColor(entry.item.kind))

    return InkWideTags(timeRange: format.timeRange(of: entry.item, withWeekday: true)) {
      if let label = entry.item.kind.label {
        InkModeTag(Text(verbatim: label.text(in: language)), accent: accent)
      }
      InkStateTag(place: entry.place, accent: accent)
    }
  }

  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - InkWideRow

/// The wide current row: the two halves on a taped panel's content.
private struct InkWideRow<Leading: View, Trailing: View>: View {
  @ViewBuilder let leading: Leading
  @ViewBuilder let trailing: Trailing

  var body: some View {
    WideRowHalves(spacing: InkScreenMetrics.panelRowSpacing * 2) {
      VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
        leading
      }
    } trailing: {
      trailing
    }
  }
}

// MARK: - InkTablePanel

/// The wide detail's table: one panel with a row per entry, dotted rules between them. It shows
/// nothing when no entry is left.
private struct InkTablePanel<Item: TimeWindow & Hashable & Sendable, Row: View>: View {
  let entries: [InkPanelEntry<Item>]
  @ViewBuilder let row: (InkPanelEntry<Item>) -> Row

  var body: some View {
    if !entries.isEmpty {
      VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
        ForEach(entries) { entry in
          if entry.id != entries.first?.id {
            InkDottedRule()
          }
          row(entry)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .inkPanel()
    }
  }
}

// MARK: - InkWideTags

/// A row's tags over its time tag, the tags leading.
private struct InkWideTags<Tags: View>: View {
  let timeRange: String
  @ViewBuilder let tags: Tags

  var body: some View {
    VStack(alignment: .leading, spacing: InkScreenMetrics.cardSpacing) {
      HStack(spacing: InkScreenMetrics.cardSpacing) {
        tags
      }
      InkTimeTag(Text(verbatim: timeRange))
    }
  }
}

// MARK: - InkWideRule

/// A Rule's icon and name in the accent, tinted to stay readable on the panel; the icon
/// takes the row's height.
private struct InkWideRule: View {
  @Environment(\.colorScheme) private var colorScheme

  let rule: RuleID
  let accent: InkAccent
  let style: InkTextStyle
  let terms: GameTerms

  var body: some View {
    HStack(spacing: InkScreenMetrics.cardSpacing) {
      Image(decorative: BundledImage.name(for: rule, size: .medium), bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
      Text(verbatim: terms.name(of: rule))
        .inkFont(style)
        .foregroundStyle(Color(accent.onPanel(in: colorScheme).foreground))
        .scaledLimitedLine(for: .sideBySide)
    }
  }
}

// MARK: - InkWideProgress

/// The wide current row's progress ring in the accent, with the countdown beside it,
/// ticking on whole seconds.
private struct InkWideProgress: View {
  @Environment(\.colorScheme) private var colorScheme

  /// The ring's stroke, as a share of its side.
  static private let lineWidthShare: CGFloat = 0.2

  let progress: WindowProgress
  let accent: InkAccent
  let writer: SentenceWriter
  let wide: WideDetailMetrics

  var body: some View {
    let side: CGFloat = wide.half.length(.wideRingSize)
    let countdown: String = writer.countdown(progress)

    HStack(spacing: InkScreenMetrics.panelRowSpacing) {
      ProgressRing(
        share: progress.sharePassed,
        color: Color(accent.base),
        lineWidth: side * Self.lineWidthShare,
        timeLeft: writer.timeLeft(progress))
        .frame(width: side, height: side)
      Text(verbatim: countdown)
        .inkFont(.caption)
        .monospacedDigit()
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
        .scaledLimitedLine(for: .sideBySide)
        .countdownRoll(value: countdown)
    }
  }
}
#endif
