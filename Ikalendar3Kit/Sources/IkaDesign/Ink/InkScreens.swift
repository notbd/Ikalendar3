//
//  InkScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkBattleScreenView

/// Ink's Battle Mode screen: ikalendar 2's primary and secondary layout on the game's materials.
/// The Mode's heading and stamp over the dotted background, an announced Splatfest's card on
/// Regular Battle's screen, the current Rotation's taped panel, then a panel per later Rotation.
/// A finished Rotation leaves and the next glides into the featured panel.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store. Pull to
/// refresh reaches its scroll view through the `refreshable` action the shared screen sets.
public struct InkBattleScreenView: View {
  @TimeSettings private var time

  private let screen: BattleScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  public init(screen: BattleScreen, terms: GameTerms, now: Date, isStale: Bool) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
  }

  public var body: some View {
    let mode: Mode = .battle(screen.mode)
    let entries: [InkPanelEntry<Rotation>] = InkPanelEntry.entries(
      current: screen.current,
      next: screen.next,
      later: screen.later)

    InkScheduleList(
      heading: InkModeHeading(mode),
      icon: ModeIcon(mode),
      accent: InkAccent(ModeColor(mode)),
      title: screen.mode.name(in: terms.language),
      reflowValue: entries.map(\.id),
      fetchTime: screen.fetchTime,
      now: now,
      isStale: isStale)
    { metrics in
      if let card = screen.announcedSplatfest {
        InkEventCard(item: .splatfest(card), terms: terms, now: now)
      }
      switch screen.current {
        case .running:
          EmptyView()
        case .paused(let returnTime):
          InkNote(text: ScreenText.paused.text(in: terms.language, format.time(returnTime, now: now)))
        case .nothingCurrent:
          InkNote(text: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach(entries) { entry in
        // A lineup's Rotations always play: a paused window is never an item.
        if let setting = entry.item.setting {
          InkBattlePanel(
            entry: entry,
            setting: setting,
            terms: terms,
            accent: InkAccent(ModeColor(screen.mode)),
            timeRange: format.range(of: entry.item, now: now),
            writer: writer,
            metrics: metrics)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(writer.sentence(for: entry.item, at: now))
        }
      }
    }
  }

  private var format: InkTimeFormat { time.inkFormat(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - InkSalmonRunScreenView

/// Ink's Salmon Run screen: a running or announced Eggstra Work on top, then a panel per Shift,
/// the current one taped, with a Big Run inline where it falls and marked. A finished Shift
/// leaves and the next takes the featured place. It receives `IkaCore` values only and reads no
/// store.
public struct InkSalmonRunScreenView: View {
  @TimeSettings private var time

  private let screen: SalmonRunScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  public init(screen: SalmonRunScreen, terms: GameTerms, now: Date, isStale: Bool) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
  }

  public var body: some View {
    let eggstraWork: [InkPanelEntry<Shift>] =
      if let running = screen.eggstraWork { [InkPanelEntry(item: running.item, place: .now(running.progress))] }
      else if let next = screen.nextEggstraWork { [InkPanelEntry(item: next, place: .next)] }
      else { [] }
    let shifts: [InkPanelEntry<Shift>] = InkPanelEntry.entries(
      current: screen.current,
      next: screen.next,
      later: screen.later)

    InkScheduleList(
      heading: InkModeHeading(.salmonRun),
      icon: .salmonRun,
      accent: InkAccent(.salmonRun),
      title: Mode.salmonRun.name(in: terms.language),
      reflowValue: (eggstraWork + shifts).map(\.id),
      fetchTime: screen.fetchTime,
      now: now,
      isStale: isStale)
    { metrics in
      ForEach(eggstraWork) { panel($0, metrics: metrics) }
      switch screen.current {
        case .running:
          EmptyView()
        case .paused,
             .nothingCurrent:
          InkNote(text: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach(shifts) { panel($0, metrics: metrics) }
    }
  }

  private func panel(_ entry: InkPanelEntry<Shift>, metrics: CellMetrics) -> some View {
    InkShiftPanel(
      entry: entry,
      terms: terms,
      timeRange: format.range(of: entry.item, now: now),
      writer: writer,
      metrics: metrics)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(writer.sentence(for: entry.item, at: now))
  }

  private var format: InkTimeFormat { time.inkFormat(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - InkScheduleList

/// What every Ink screen shares around its panels: the board, the heading with the Mode stamp
/// that docks into the bar, the panels' metrics for the screen's width and text size, the reflow
/// when a panel leaves, and the fetch time at the end.
struct InkScheduleList<ReflowValue: Equatable, Panels: View>: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  let heading: InkModeHeading
  /// The stamp's icon.
  let icon: ModeIcon
  /// The stamp's splat and the heading's form tag.
  let accent: InkAccent
  /// The screen's full name, for the navigation bar.
  let title: String
  /// The panels' identities, in order: the list reflows when they change.
  let reflowValue: ReflowValue
  let fetchTime: Date
  let now: Date
  let isStale: Bool
  @ViewBuilder let panels: (CellMetrics) -> Panels

  /// The width of the list's column.
  @State private var width: CGFloat = 0

  var body: some View {
    let metrics: CellMetrics = .init(width: width - InkMetrics.panelPadding * 2, dynamicTypeSize: dynamicTypeSize)

    ScrollView {
      LazyVStack(spacing: InkScreenMetrics.panelSpacing) {
        InkModeHeadingView(
          heading: heading,
          accent: accent,
          arrangement: metrics.arrangement,
          stampReserve: width * InkScreenMetrics.stampReservedShare)
        panels(metrics)
        FetchTimeLabel(fetchTime: fetchTime, now: now, isStale: isStale)
          // On Ink's black background in both appearances, until ticket 56 designs the light one.
          .environment(\.colorScheme, .dark)
      }
      .padding(.horizontal, InkScreenMetrics.screenPadding)
      .padding(.bottom, InkScreenMetrics.panelSpacing)
      .onGeometryChange(for: CGFloat.self) { proxy in
        proxy.size.width - InkScreenMetrics.screenPadding * 2
      } action: { newWidth in
        width = newWidth
      }
    }
    .listReflow(value: reflowValue)
    .background { InkBackground().ignoresSafeArea() }
    .inkModeStamp(icon: icon, accent: accent, title: title)
  }
}

// MARK: - InkModeHeadingView

/// The Mode's name over the list in the heavy face, with Anarchy Battle's or Splatfest Battle's
/// form on a tag in the accent under it. It leaves the trailing side to the stamp and is at least as tall as the splat,
/// and
/// from the first accessibility text size sits under the stamp at full width instead, so the name
/// wraps rather than truncates.
private struct InkModeHeadingView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.gameLanguage) private var language

  let heading: InkModeHeading
  let accent: InkAccent
  let arrangement: CellArrangement
  /// The width beside the heading the stamp takes.
  let stampReserve: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: InkScreenMetrics.headingSpacing) {
      Text(verbatim: heading.name.text(in: language))
        .inkFont(.title)
        // The heavy face's tall line box leaves a gap between wrapped lines that the game's
        // headings do not have.
        .lineHeight(.tight)
        .foregroundStyle(Color(InkPair.backgroundText.colors(in: colorScheme).foreground))
        .fixedSize(horizontal: false, vertical: true)
      if let form = heading.form {
        InkModeTag(Text(verbatim: form.text(in: language)), accent: accent)
      }
    }
    .padding(InkScreenMetrics.headingPadding)
    .padding(.trailing, arrangement == .sideBySide ? stampReserve : 0)
    .padding(.top, arrangement == .stacked ? InkScreenMetrics.splatSize : 0)
    // Beside the stamp, the first panel starts under the splat, so the splat never covers its
    // state tag.
    .frame(
      maxWidth: .infinity,
      minHeight: arrangement == .sideBySide ? InkScreenMetrics.splatSize - InkScreenMetrics.splatPanelOverlap : nil,
      alignment: .topLeading)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }
}

// MARK: - InkNote

/// A taped panel in the featured place that says why nothing is current: a pause by a Splatfest,
/// with the return time, or nothing on right now.
struct InkNote: View {
  let text: String

  var body: some View {
    Text(verbatim: text)
      .inkFont(.label)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .inkPanel(isTaped: true)
  }
}
#endif
