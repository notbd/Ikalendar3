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

/// Ink's Battle Mode screen: plain rows on Ink's panels and dotted background, a stand-in until
/// ticket 27 draws the full layout.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store. Pull to
/// refresh reaches its scroll view through the `refreshable` action the shared screen sets.
public struct InkBattleScreenView: View {
  @Environment(\.timeZone) private var timeZone

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
    ScrollView {
      LazyVStack(spacing: 12) {
        if let card = screen.announcedSplatfest {
          SplatfestCardView(splatfest: card.splatfest, art: card.art, terms: terms, style: .ink, now: now)
            .inkPanel()
        }
        switch screen.current {
          case .running(let running):
            panel(running.item, progress: running.progress)
          case .paused(let returnTime):
            note(ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: now)))
          case .nothingCurrent:
            note(ScreenText.nothingCurrent.text(in: terms.language))
        }
        ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { rotation in
          panel(rotation, progress: nil)
        }
        FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
      }
      .padding()
    }
    .background(InkBackground())
  }

  /// A Rotation's panel; the current one is taped and carries its progress.
  private func panel(_ rotation: Rotation, progress: WindowProgress?) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: format.timeRange(of: rotation))
        .inkFont(.body)
      Text(verbatim: rotation.setting.map { terms.name(of: $0.rule) } ?? "")
        .inkFont(progress == nil ? .label : .headline)
      Text(verbatim: rotation.setting?.stages.map(terms.name(of:)).joined(separator: " · ") ?? "")
        .inkFont(.caption)
      if let progress {
        ProgressView(value: progress.sharePassed) {
          Text(verbatim: writer.timeLeft(progress))
            .inkFont(.caption)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel(isTaped: progress != nil)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: rotation, at: now))
  }

  private func note(_ text: String) -> some View {
    Text(verbatim: text)
      .inkFont(.label)
      .frame(maxWidth: .infinity, alignment: .leading)
      .inkPanel(isTaped: true)
  }

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
  private var writer: SentenceWriter { .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle) }
}

// MARK: - InkSalmonRunScreenView

/// Ink's Salmon Run screen: plain rows on Ink's panels and dotted background, a stand-in until
/// ticket 27 draws the full layout. It receives `IkaCore` values only and reads no store.
public struct InkSalmonRunScreenView: View {
  @Environment(\.timeZone) private var timeZone

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
    ScrollView {
      LazyVStack(spacing: 12) {
        if let eggstraWork = screen.eggstraWork {
          panel(eggstraWork.item, progress: eggstraWork.progress)
        }
        else if let nextEggstraWork = screen.nextEggstraWork {
          panel(nextEggstraWork, progress: nil)
        }
        switch screen.current {
          case .running(let running):
            panel(running.item, progress: running.progress)
          case .paused,
               .nothingCurrent:
            Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
              .inkFont(.label)
              .frame(maxWidth: .infinity, alignment: .leading)
              .inkPanel(isTaped: true)
        }
        ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { shift in
          panel(shift, progress: nil)
        }
        FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
      }
      .padding()
    }
    .background(InkBackground())
  }

  /// A Shift's panel; a running one is taped and carries its progress.
  private func panel(_ shift: Shift, progress: WindowProgress?) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: format.timeRange(of: shift, withWeekday: true))
        .inkFont(.body)
      if let label = shift.kind.label {
        Text(verbatim: label.text(in: terms.language))
          .inkFont(.tag)
      }
      Text(verbatim: terms.name(of: shift.stage))
        .inkFont(progress == nil ? .label : .headline)
      Text(verbatim: shift.weapons.map(terms.name(of:)).joined(separator: " · "))
        .inkFont(.caption)
      if let kingSalmonid = shift.kingSalmonid {
        Text(verbatim: terms.name(of: kingSalmonid))
          .inkFont(.caption)
      }
      if let progress {
        ProgressView(value: progress.sharePassed) {
          Text(verbatim: writer.timeLeft(progress))
            .inkFont(.caption)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel(isTaped: progress != nil)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: shift, at: now))
  }

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
  private var writer: SentenceWriter { .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle) }
}
#endif
