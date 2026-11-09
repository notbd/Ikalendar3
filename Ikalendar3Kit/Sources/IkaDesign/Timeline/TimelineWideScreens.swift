//
//  TimelineWideScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineWideBattleScreenView

/// Timeline's wide Battle Mode detail on iPad and Mac: the black header (with the Series and Open
/// strip on Anarchy) and an announced Splatfest's card as on iPhone, then, in a centred column,
/// the current Rotation as one wide row (start pin, Rule, progress ring with "Now" and the
/// countdown beside both Stages) over one table of every later Rotation, each on its 24-hour pin
/// with a day mark where the table reaches a new day.
///
/// It receives `IkaCore` values only and reads no store.
public struct TimelineWideBattleScreenView: View {
  @Environment(\.timeZone) private var timeZone
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
    let entries: [TimelineEntry<Rotation>] = TimelineEntry.entries(of: screen)
    let color: ModeColor = .init(screen.mode)
    let format: TimelineFormat = .init(language: terms.language, timeZone: timeZone)
    let writer: SentenceWriter = time.writer(terms)

    TimelineScheduleList(
      icon: ModeIcon(Mode.battle(screen.mode)),
      title: screen.mode.name(in: terms.language),
      headerName: screen.mode.timelineHeaderName(in: terms.language),
      reflowValue: entries.map(\.id))
    {
      if screen.mode.isAnarchy {
        TimelineFormStrip(shown: screen.mode, language: terms.language)
      }
      if let card = screen.announcedSplatfest {
        SplatfestCardView(splatfest: card.splatfest, art: card.art, terms: terms, style: .timeline, now: now)
          .padding(.horizontal, TimelineMetrics.contentTrailing)
          .padding(.top, TimelineMetrics.axisTop)
      }
    } axis: { _ in
      TimelineWideColumn(entries: entries, format: format) { entry in
        switch entry {
          case .item(let rotation, let progress?):
            if let setting = rotation.setting {
              TimelineWideRow(color: color) {
                TimelinePin(text: format.pin(rotation.startTime), color: color, isCurrent: true)
                TimelineWideRule(rule: setting.rule, size: wide.half.length(.battleRuleSectionHeight), terms: terms)
                TimelineWideProgress(progress: progress, color: color, writer: writer, now: now, wide: wide)
              } trailing: {
                TimelineStageStrip(stages: setting.stages, terms: terms, arrangement: .sideBySide)
              }
            }

          case .item:
            // A Rotation still to come: in the table.
            EmptyView()

          case .paused(let returnTime):
            TimelineStatusContent(text: ScreenText.paused.text(
              in: terms.language,
              time.format(terms.language).time(returnTime, relativeTo: now)))

          case .nothingCurrent:
            TimelineStatusContent(text: ScreenText.nothingCurrent.text(in: terms.language))
        }
      } row: { rotation in
        if let setting = rotation.setting {
          WideTableColumns(wide: wide, spacing: TimelineWideMetrics.spacing) {
            TimelinePin(text: format.pin(rotation.startTime), color: color, isCurrent: false)
          } middle: {
            TimelineWideRule(rule: setting.rule, size: wide.half.length(.tableRuleIconHeight), terms: terms)
          } trailing: {
            TimelineStageStrip(stages: setting.stages, terms: terms, arrangement: .sideBySide)
              .frame(width: wide.half.length(.tableThumbnailWidth) * CGFloat(setting.stages.count))
          }
        }
      } sentence: { entry in
        entry.sentence(of: screen.mode, writer: writer, at: now)
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
    .contentMargins(.horizontal, wide.sideMargin, for: .scrollContent)
  }
}

// MARK: - TimelineWideSalmonRunScreenView

/// Timeline's wide Salmon Run detail on iPad and Mac: the black header, then, in a centred
/// column, each running Shift (an Eggstra Work beside a regular one included) as one wide row
/// (kind tag, time range, progress ring with "Now" and the countdown beside the Stage, the four
/// weapons and the King Salmonid) over one table of every other Shift with its time range, Stage
/// and weapons, the running or announced Eggstra Work on top as on iPhone.
///
/// It receives `IkaCore` values only and reads no store.
public struct TimelineWideSalmonRunScreenView: View {
  @Environment(\.timeZone) private var timeZone
  @TimeSettings private var time

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
    let entries: [TimelineEntry<Shift>] = TimelineEntry.entries(of: screen)
    let format: TimelineFormat = .init(language: terms.language, timeZone: timeZone)
    let writer: SentenceWriter = time.writer(terms)
    let name: String = Mode.salmonRun.name(in: terms.language)

    TimelineScheduleList(
      icon: ModeIcon(Mode.salmonRun),
      title: name,
      headerName: name,
      reflowValue: entries.map(\.id))
    {
      EmptyView()
    } axis: { _ in
      TimelineWideColumn(entries: entries, format: nil) { entry in
        switch entry {
          case .item(let shift, let progress?):
            let color: ModeColor = .init(shift.kind)
            TimelineWideRow(color: color) {
              time(of: shift, format: format)
              TimelineWideProgress(progress: progress, color: color, writer: writer, now: now, wide: wide)
            } trailing: {
              VStack(spacing: TimelineWideMetrics.spacing) {
                TimelineStageStrip(stages: [shift.stage], terms: terms, arrangement: .sideBySide)
                TimelineWeapons(weapons: shift.weapons, kingSalmonid: shift.kingSalmonid, terms: terms)
              }
            }

          case .item:
            // A Shift that does not run: in the table.
            EmptyView()

          case .paused,
               .nothingCurrent:
            // Salmon Run is never paused: any status is nothing current.
            TimelineStatusContent(text: ScreenText.nothingCurrent.text(in: terms.language))
        }
      } row: { shift in
        WideTableColumns(wide: wide, spacing: TimelineWideMetrics.spacing) {
          time(of: shift, format: format)
        } middle: {
          TimelineStageStrip(stages: [shift.stage], terms: terms, arrangement: .sideBySide)
            .frame(width: wide.half.length(.tableThumbnailWidth))
        } trailing: {
          TimelineWeapons(weapons: shift.weapons, kingSalmonid: nil, terms: terms)
            .fixedSize()
        }
      } sentence: { entry in
        entry.item.map { writer.sentence(for: $0, at: now) } ?? ScreenText.nothingCurrent.text(in: terms.language)
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
    .contentMargins(.horizontal, wide.sideMargin, for: .scrollContent)
  }

  /// A Shift's kind tag over its time range with the weekdays.
  @ViewBuilder
  private func time(of shift: Shift, format: TimelineFormat) -> some View {
    if let label = shift.kind.label {
      TimelineKindTag(label: label, kind: shift.kind, language: terms.language)
    }
    Text(verbatim: format.timeRange(from: shift.startTime, to: shift.endTime))
      .ikaFont(.light, size: 14, relativeTo: .subheadline)
      .scaledLimitedLine(for: .sideBySide)
      .foregroundStyle(.white)
  }
}

// MARK: - TimelineWideMetrics

/// The wide detail's sizes on Timeline's page. Ticket 58 judges the final look.
private enum TimelineWideMetrics {
  /// Space between parts of a row, and between the current row and the table.
  static let spacing: CGFloat = 12
  /// A row's inner padding.
  static let rowPadding: CGFloat = 12
  /// The rounding of the current row's plate.
  static let plateCornerRadius: CGFloat = 12
  /// The hairline between table rows.
  static let dividerOpacity: Double = 0.15
}

// MARK: - TimelineWideColumn

/// The wide detail's column on Timeline's page: every entry that is not a later item (the
/// current rows, or why nothing is on) in order, then one table of the later items, each a row
/// with a day mark over it where a Battle Mode's table reaches a new day. VoiceOver reads each
/// row as one element, its entry's sentence.
private struct TimelineWideColumn<Item: TimeWindow & Hashable & Sendable, Featured: View, Row: View>: View {
  let entries: [TimelineEntry<Item>]
  /// Marks days in the table: Rotations carry no day of their own, a Shift's range carries its
  /// weekdays, so it passes `nil`.
  let format: TimelineFormat?
  @ViewBuilder let featured: (TimelineEntry<Item>) -> Featured
  @ViewBuilder let row: (Item) -> Row
  let sentence: (TimelineEntry<Item>) -> String

  var body: some View {
    let table: [TimelineEntry<Item>] = entries.filter { $0.item != nil && $0.progress == nil }

    VStack(alignment: .leading, spacing: TimelineWideMetrics.spacing) {
      ForEach(entries.filter { $0.item == nil || $0.progress != nil }) { entry in
        featured(entry)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(sentence(entry))
      }
      if !table.isEmpty {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(Array(zip(table, dayMarks(of: table))), id: \.0.id) { entry, dayMark in
            if entry.id != table.first?.id {
              Rectangle()
                .fill(.white.opacity(TimelineWideMetrics.dividerOpacity))
                .frame(height: 1)
            }
            if let dayMark {
              Text(verbatim: dayMark)
                .ikaFont(.light, size: 14, relativeTo: .footnote)
                .foregroundStyle(TimelinePalette.secondaryText)
                .padding(.top, TimelineWideMetrics.rowPadding)
                .accessibilityAddTraits(.isHeader)
            }
            if let item = entry.item {
              row(item)
                .padding(.vertical, TimelineWideMetrics.rowPadding)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(sentence(entry))
            }
          }
        }
      }
    }
    .padding(.horizontal, TimelineMetrics.contentTrailing)
    .padding(.top, TimelineMetrics.axisTop)
  }

  /// Each table row's day mark, where its start falls on a new day after the start above it.
  private func dayMarks(of table: [TimelineEntry<Item>]) -> [String?] {
    guard let format else { return table.map { _ in nil } }

    var previous: Date?
    return table.map { entry in
      guard let start = entry.item?.startTime else { return nil }

      defer { previous = start }
      return format.startsNewDay(start, after: previous) ? format.day(start) : nil
    }
  }
}

// MARK: - TimelineWideRow

/// The wide current row on a black plate with a Mode-colour edge, where the axis line would run.
private struct TimelineWideRow<Leading: View, Trailing: View>: View {
  let color: ModeColor
  @ViewBuilder let leading: Leading
  @ViewBuilder let trailing: Trailing

  var body: some View {
    WideRowHalves(spacing: TimelineWideMetrics.spacing) {
      VStack(alignment: .leading, spacing: TimelineWideMetrics.spacing) {
        leading
      }
    } trailing: {
      trailing
    }
    .padding(TimelineWideMetrics.rowPadding)
    .padding(.leading, TimelineMetrics.axisLineWidth)
    .background(alignment: .leading) {
      Rectangle()
        .fill(Color(color.base))
        .frame(width: TimelineMetrics.axisLineWidth)
    }
    .background(TimelinePalette.header)
    .clipShape(.rect(cornerRadius: TimelineWideMetrics.plateCornerRadius))
  }
}

// MARK: - TimelineWideRule

/// A Rule's icon and name in the slot's heavy face.
private struct TimelineWideRule: View {
  let rule: RuleID
  /// The icon's side.
  let size: CGFloat
  let terms: GameTerms

  var body: some View {
    HStack(spacing: 8) {
      Image(decorative: BundledImage.name(for: rule, size: .medium), bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
      Text(verbatim: terms.name(of: rule))
        .ikaFont(.heavy, size: 18, relativeTo: .headline)
        .scaledLimitedLine(for: .sideBySide)
        .foregroundStyle(.white)
    }
  }
}

// MARK: - TimelineWideProgress

/// The wide current row's progress ring in the Mode colour, with "Now" and the countdown beside
/// it.
private struct TimelineWideProgress: View {
  /// The ring's stroke, as a share of its side.
  static private let lineWidthShare: CGFloat = 0.2

  let progress: WindowProgress
  let color: ModeColor
  let writer: SentenceWriter
  let now: Date
  let wide: WideDetailMetrics

  var body: some View {
    let side: CGFloat = wide.half.length(.wideRingSize)

    HStack(spacing: TimelineWideMetrics.spacing) {
      ProgressRing(
        share: progress.sharePassed,
        color: Color(color.base),
        lineWidth: side * Self.lineWidthShare,
        timeLeft: writer.timeLeft(progress))
        .frame(width: side, height: side)
      TimelineNowTag(timeLeft: progress.timeLeft, color: color, language: writer.terms.language, now: now)
    }
  }
}
#endif
