//
//  TimelineScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineBattleScreenView

/// Timeline's Battle Mode screen, after SplatNet 3's schedule page: a black header with the Mode,
/// the Series and Open strip on Anarchy, an announced Splatfest's card, then every Rotation top to bottom on a
/// Mode-colour time
/// axis with 24-hour pins, the current one's progress filled in along the axis.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store. Pull to
/// refresh reaches its list through the `refreshable` action the shared screen sets. A finished
/// Rotation leaves the axis as the app clock passes its end, and the next one becomes current.
public struct TimelineBattleScreenView: View {
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
    let entries: [TimelineEntry<Rotation>] = TimelineEntry.entries(of: screen)
    let color: TimelineTint = .init(ModeColor(screen.mode))
    let writer: SentenceWriter = time.writer(terms)

    TimelineScheduleList(
      icon: ModeIcon(Mode.battle(screen.mode)),
      title: screen.mode.name(in: terms.language),
      headerName: headerName,
      reflowValue: entries.map(\.id))
    {
      if isAnarchy {
        TimelineFormStrip(shown: screen.mode, language: terms.language)
      }
      if let card = screen.announcedSplatfest {
        TimelineSplatfestCard(splatfest: card.splatfest, art: card.art, terms: terms, now: now)
          .padding(.horizontal, TimelineMetrics.contentTrailing)
          .padding(.top, TimelineMetrics.axisTop)
      }
    } axis: { arrangement in
      TimelineAxis(
        entries: entries,
        format: time.timelineFormat(terms.language),
        arrangement: arrangement)
      { entry in
        switch entry {
          case .item(let rotation, let progress):
            if let setting = rotation.setting {
              TimelineRotationContent(
                setting: setting,
                progress: progress,
                color: color,
                terms: terms,
                now: now,
                arrangement: arrangement)
            }

          case .paused(let returnTime):
            TimelineStatusContent(text: ScreenText.paused.text(
              in: terms.language,
              format.time(returnTime, relativeTo: now)))

          case .nothingCurrent:
            TimelineStatusContent(text: ScreenText.nothingCurrent.text(in: terms.language))
        }
      } color: { _ in
        color
      } sentence: { entry in
        sentence(for: entry, writer: writer)
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }

  /// Whether the screen shows a form of Anarchy Battle, which the header names without its form
  /// and the strip below it marks.
  private var isAnarchy: Bool {
    screen.mode == .anarchySeries || screen.mode == .anarchyOpen
  }

  /// The header's name: "Anarchy Battle" over the strip, else the Battle Mode's name.
  private var headerName: String {
    isAnarchy ? ModeLabel.anarchyBattle.text(in: terms.language) : screen.mode.name(in: terms.language)
  }

  private func sentence(for entry: TimelineEntry<Rotation>, writer: SentenceWriter) -> String {
    switch entry {
      case .item(let rotation, _): writer.sentence(for: rotation, at: now)
      case .paused(let returnTime): writer.sentence(forPauseOf: screen.mode, returningAt: returnTime)
      case .nothingCurrent: ScreenText.nothingCurrent.text(in: terms.language)
    }
  }

  private var format: ScheduleFormat { time.format(terms.language) }
}

// MARK: - TimelineSalmonRunScreenView

/// Timeline's Salmon Run screen: the black header, then the running or announced Eggstra Work on
/// top and every
/// Shift on the time axis with its Stage, four weapons, King Salmonid and time range, a Big Run
/// inline where it falls and marked in its colour. It receives `IkaCore` values only and reads no
/// store.
public struct TimelineSalmonRunScreenView: View {
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
    let entries: [TimelineEntry<Shift>] = TimelineEntry.entries(of: screen)
    let format: TimelineFormat = time.timelineFormat(terms.language)
    let writer: SentenceWriter = time.writer(terms)
    let name: String = Mode.salmonRun.name(in: terms.language)

    TimelineScheduleList(
      icon: ModeIcon(Mode.salmonRun),
      title: name,
      headerName: name,
      reflowValue: entries.map(\.id))
    {
      EmptyView()
    } axis: { arrangement in
      TimelineAxis(
        entries: entries,
        format: format,
        arrangement: arrangement)
      { entry in
        if case .item(let shift, let progress) = entry {
          TimelineShiftContent(
            shift: shift,
            progress: progress,
            terms: terms,
            format: format,
            now: now,
            arrangement: arrangement)
        }
        else {
          // Salmon Run is never paused: any status is nothing current.
          TimelineStatusContent(text: ScreenText.nothingCurrent.text(in: terms.language))
        }
      } color: { entry in
        TimelineTint(entry.item.map { ModeColor($0.kind) } ?? .salmonRun)
      } sentence: { entry in
        entry.item.map { writer.sentence(for: $0, at: now) } ?? ScreenText.nothingCurrent.text(in: terms.language)
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }
}

// MARK: - TimelineBackground

/// SplatNet 3's dark page, behind every Timeline screen and the Debug event card gallery.
public struct TimelineBackground: View {
  public init() { }

  public var body: some View {
    TimelinePalette.page
  }
}

// MARK: - TimelineScheduleList

/// What every Timeline screen shares: SplatNet 3's dark page under the black header, the axis sized
/// for the text size, entries moving into place as the clock changes them and, on iPhone and
/// iPad, the header's stamp docking into the navigation bar badge, the inline title fading in
/// with it.
///
/// The page stays dark in light appearance until ticket 57 designs Timeline's light look, so the
/// list and the navigation bar take the dark scheme.
struct TimelineScheduleList<AboveAxis: View, Axis: View, Footer: View, ReflowValue: Equatable>: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  /// How far the header's stamp has docked into the navigation bar badge.
  @State private var dockProgress: Double = 0

  let icon: ModeIcon
  /// The navigation title, which names the Mode in full.
  let title: String
  /// The Mode's name in the header.
  let headerName: String
  let reflowValue: ReflowValue
  /// What sits between the header and the axis: the strip of forms, a Splatfest's card.
  @ViewBuilder let aboveAxis: () -> AboveAxis
  @ViewBuilder let axis: (CellArrangement) -> Axis
  @ViewBuilder let footer: () -> Footer

  var body: some View {
    GeometryReader { geometry in
      let arrangement: CellArrangement = CellMetrics(width: geometry.size.width, dynamicTypeSize: dynamicTypeSize)
        .arrangement

      ScrollView {
        VStack(spacing: 0) {
          TimelineHeader(icon: icon, name: headerName, dockProgress: dockProgress, arrangement: arrangement)
          aboveAxis()
          axis(arrangement)
          footer()
            .padding(.horizontal, TimelineMetrics.contentTrailing)
            .padding(.vertical, 16)
        }
        .listReflow(value: reflowValue)
      }
      .background(TimelineBackground())
      .environment(\.colorScheme, .dark)
      #if os(iOS)
      .modeStampDock(icon: icon, title: title, dockProgress: $dockProgress)
      #endif
    }
  }
}

#if os(iOS)
extension View {
  /// Tracks how far the list has scrolled from rest into `dockProgress`, with ticket 12's stamp
  /// math, and shows the navigation bar badge and the inline title fading in with it.
  ///
  /// Timeline's title is always inline, so the top inset never shrinks as Classic's large title
  /// collapses: the current inset is where the list rests. While a refresh runs, the inset grows
  /// by the spinner's height, which keeps the travel at rest.
  fileprivate func modeStampDock(icon: ModeIcon, title: String, dockProgress: Binding<Double>) -> some View {
    let badgeOpacity: Double = ModeStampMath.badgeOpacity(progress: dockProgress.wrappedValue)

    return onScrollGeometryChange(for: Double.self) { geometry in
      ModeStampMath.dockProgress(
        contentOffsetY: geometry.contentOffset.y,
        restingTopInset: geometry.contentInsets.top)
    } action: { _, progress in
      dockProgress.wrappedValue = progress
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .toolbar {
      // The header names the Mode at rest; the title takes over once the header scrolls away.
      ToolbarItem(placement: .principal) {
        Text(verbatim: title)
          .ikaFont(.heavy, size: 17, relativeTo: .headline)
          .lineLimit(1)
          .foregroundStyle(.white)
          .opacity(badgeOpacity)
          .accessibilityAddTraits(.isHeader)
      }
      ToolbarItem(placement: .topBarTrailing) {
        TimelineModeBadge(icon: icon)
          .opacity(badgeOpacity)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
      // The badge draws its own glass, so the glass fades in with the badge.
      .sharedBackgroundVisibility(.hidden)
    }
  }
}
#endif
#endif
