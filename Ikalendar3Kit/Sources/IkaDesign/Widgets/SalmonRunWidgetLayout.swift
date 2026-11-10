//
//  SalmonRunWidgetLayout.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)
import IkaCore
import SwiftUI
import WidgetKit

// MARK: - SalmonRunWidgetLayout

/// The Salmon Run widget in Ink at `family`: the current Shift's kind heading it, then its Stage,
/// weapons, King Salmonid and countdown, on Ink's dotted background.
public struct SalmonRunWidgetLayout: View {
  let entry: ScheduleWidgetEntry<SalmonRunWidgetContent>
  let family: WidgetFamily

  public init(entry: ScheduleWidgetEntry<SalmonRunWidgetContent>, family: WidgetFamily) {
    self.entry = entry
    self.family = family
  }

  public var body: some View {
    Group {
      if let schedule = entry.schedule {
        content(schedule)
      }
      else {
        EmptyWidgetView()
      }
    }
    .environment(\.gameLanguage, entry.terms.language)
    .containerBackground(for: .widget) {
      InkBackground()
    }
  }

  private func content(_ schedule: WidgetEntry<SalmonRunWidgetContent>) -> some View {
    let shift = schedule.content.current.item

    return VStack(alignment: .leading, spacing: 6) {
      ModeHeading(kind: shift?.kind ?? .regular, in: entry.terms.language) {
        FreshnessLabel(entry: schedule, showsFetchTime: family != .systemSmall)
      }
      if let shift {
        ShiftView(shift: shift, terms: entry.terms, isWide: family != .systemSmall)
      }
      else {
        Text(verbatim: ScreenText.nothingCurrent.text(in: entry.terms.language))
          .inkFont(.label)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      Spacer(minLength: 0)
    }
  }
}

// MARK: - ShiftView

/// The current Shift: its Stage as an Ink card, its four weapons (random ones as the game's
/// question marks), its King Salmonid and the system's countdown to its end. Stacked in the small
/// widget; the Stage beside the rest where `isWide`. VoiceOver reads it as one element: the
/// Shift's sentence, then the countdown as its value, so it hears the time left when it reads
/// (`WidgetAccessibility`).
struct ShiftView: View {
  @TimeSettings private var time
  @ScaledMetric(relativeTo: .caption) private var kingSalmonidSide: CGFloat = 30

  let shift: Shift
  let terms: GameTerms
  let isWide: Bool

  var body: some View {
    Group {
      if isWide {
        HStack(alignment: .top, spacing: 12) {
          stage
          VStack(alignment: .leading, spacing: 8) {
            WeaponIcons(weapons: shift.weapons, maxSide: 32)
            HStack(spacing: 8) {
              kingSalmonid
              countdown
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      else {
        VStack(alignment: .leading, spacing: 6) {
          HStack(alignment: .bottom, spacing: 6) {
            stage
            kingSalmonid
          }
          // Room for the Stage's name tag, which straddles the picture's bottom edge.
          .padding(.bottom, 10)
          WeaponIcons(weapons: shift.weapons, maxSide: 24)
          countdown
        }
      }
    }
    .widgetAccessibility(WidgetAccessibility(shift, writer: time.writer(terms), isCurrent: true))
  }

  private var stage: some View {
    InkStageCard(stage: shift.stage, name: Text(verbatim: terms.name(of: shift.stage)), imageSize: .medium)
      .frame(maxWidth: .infinity)
  }

  @ViewBuilder private var kingSalmonid: some View {
    if let kingSalmonid = shift.kingSalmonid {
      Image(decorative: BundledImage.name(for: kingSalmonid, size: .medium), bundle: BundledImage.catalogBundle)
        .resizable()
        .widgetAccentedRenderingMode(.desaturated)
        .scaledToFit()
        .frame(width: kingSalmonidSide, height: kingSalmonidSide)
    }
  }

  private var countdown: some View {
    InkTimeTag(Text(timerInterval: shift.startTime ... shift.endTime))
  }
}

// MARK: - WeaponIcons

/// A Shift's four weapons spread over a row as wide as it is offered, each as its bundled picture
/// up to `maxSide` points; a random one shows the game's green or golden question mark.
/// Decorative: the Shift's sentence names them.
struct WeaponIcons: View {
  @ScaledMetric private var maxSide: CGFloat

  private let weapons: [WeaponID]

  init(weapons: [WeaponID], maxSide: CGFloat) {
    self.weapons = weapons
    _maxSide = ScaledMetric(wrappedValue: maxSide, relativeTo: .caption)
  }

  var body: some View {
    HStack(spacing: 4) {
      ForEach(Array(weapons.enumerated()), id: \.offset) { _, weapon in
        Image(decorative: BundledImage.name(for: weapon, size: .medium), bundle: BundledImage.catalogBundle)
          .resizable()
          .widgetAccentedRenderingMode(.desaturated)
          .scaledToFit()
          .frame(maxWidth: maxSide, maxHeight: maxSide)
          .frame(maxWidth: .infinity)
      }
    }
  }
}
#endif
