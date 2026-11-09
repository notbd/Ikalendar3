//
//  TabMenuView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - TabMenuView

/// The Series and Open (or Open and Pro) menu: a glass panel above the selected tab, one row per
/// Battle Mode with its Mode summary.
///
/// OS 26 has no menu on an iPhone tab bar item: a long press on a `Tab` with a `contextMenu` shows
/// nothing, and a `Tab`'s `popover` stops the app ("UIViewController cannot be shared between
/// multiple UITab"). So the second tap reaches `AppStatus.select(_:)` through
/// `interceptingTabReselection`, and `ModeTabsView` draws this panel as an overlay.
///
/// For VoiceOver the panel is modal: focus moves to the selected option when it opens, and the
/// escape gesture closes it, as a tap outside it does.
struct TabMenuView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(\.gameLanguage) private var language

  /// The option VoiceOver focuses.
  @AccessibilityFocusState private var focusedMode: RotationMode?

  /// The menu shown.
  let menu: TabMenu
  /// The Battle Mode its tab shows now, which carries a checkmark.
  let selection: RotationMode
  /// Switches the tab to an option's Battle Mode.
  let choose: (TabMenuOption) -> Void
  /// Closes the menu with no change.
  let dismiss: () -> Void

  var body: some View {
    // As wide as the widest row while the screen holds it, so both rows share one width and the
    // panel hugs the tab; else as wide as the screen offers, the texts wrapping, and scrolling once
    // the rows grow taller than the screen.
    ViewThatFits {
      rows
        .fixedSize(horizontal: true, vertical: false)
      ViewThatFits(in: .vertical) {
        rows
        ScrollView {
          rows
        }
        .scrollBounceBehavior(.basedOnSize)
        // Next to the status bar, a scroll view draws its rows on under it, past the panel.
        .clipShape(Self.panelShape)
      }
    }
    // Regular glass in both colour schemes: the clear glass the adaptive effect uses on dark lets
    // the list show through the text.
    .glassEffect(.regular.interactive(), in: Self.panelShape)
    .accessibilityElement(children: .contain)
    .accessibilityAddTraits(.isModal)
    .accessibilityAction(.escape, dismiss)
    .onAppear { focusedMode = selection }
  }

  static private let panelShape: RoundedRectangle = .rect(cornerRadius: 28)

  private var rows: some View {
    let now = clock.now
    let terms = engine.snapshot.terms(in: language)

    return VStack(spacing: 0) {
      ForEach(engine.snapshot.options(of: menu, at: now), id: \.mode) { option in
        Button { choose(option) } label: {
          TabMenuRow(option: option, isSelected: option.mode == selection, terms: terms, now: now)
        }
        .buttonStyle(.plain)
        .accessibilityFocused($focusedMode, equals: option.mode)
      }
    }
    .padding(.vertical, 6)
  }
}

// MARK: - TabMenuRow

/// One option as a Mode summary: the Mode icon in a ring of the share passed, the Mode's name,
/// the current Rule and time left, and a checkmark on the Battle Mode the tab shows.
private struct TabMenuRow: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @TimeSettings private var time

  @ScaledMetric(relativeTo: .headline) private var ringSize: CGFloat = 36

  let option: TabMenuOption
  let isSelected: Bool
  let terms: GameTerms
  let now: Date

  var body: some View {
    // From the first accessibility size the ring sits above the texts, which then have the row's
    // width to wrap in.
    let summaryLayout: AnyLayout =
      switch CellArrangement(dynamicTypeSize) {
        case .sideBySide: .init(HStackLayout(spacing: 12))
        case .stacked: .init(VStackLayout(alignment: .leading, spacing: 8))
      }

    HStack(spacing: 16) {
      summaryLayout {
        ZStack {
          // The row's text reads the time left, so VoiceOver skips the ring.
          ProgressRing(share: option.summary?.progress?.sharePassed ?? 0, color: ringColor, lineWidth: 3, timeLeft: nil)
          Image(
            decorative: BundledImage.name(for: ModeIcon(option.mode), size: .small),
            bundle: BundledImage.catalogBundle)
            .resizable()
            .scaledToFit()
            .padding(7)
        }
        .frame(width: ringSize, height: ringSize)

        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: option.mode.name(in: terms.language))
            .font(.headline)
          if let summary {
            Text(verbatim: summary)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }
        .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Image(systemName: "checkmark")
        .font(.body.weight(.semibold))
        .opacity(isSelected ? 1 : 0)
        // The row's selected trait says it.
        .accessibilityHidden(true)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  /// The Mode colour; Splatfest Battle, which has none, takes the neutral tint its progress
  /// shows in elsewhere.
  private var ringColor: Color {
    switch option.mode {
      case .battle(let mode): Color(ModeColor(mode).base)
      case .splatfestBattle: .primary
    }
  }

  /// The summary's line, worded as the sidebar's: the current Rule and time left, the pause with
  /// the return time, or nothing on; none before the Mode has a screen.
  private var summary: String? {
    option.summary.map { summary in
      SidebarRowContent(row: .mode(summary), writer: time.writer(terms), format: time.format(terms.language), now: now)
        .summary
    }
  }
}
