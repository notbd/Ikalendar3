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
/// Battle Mode with its Mode summary, the current Rule and time left.
///
/// OS 26 has no menu on an iPhone tab bar item: a long press on a `Tab` with a `contextMenu` shows
/// nothing, and a `Tab`'s `popover` stops the app ("UIViewController cannot be shared between
/// multiple UITab"). So the second tap reaches `AppStatus.select(_:)` through
/// `interceptingTabReselection`, and `ModeTabsView` draws this panel as an overlay.
struct TabMenuView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(\.gameLanguage) private var language

  /// The menu shown.
  let menu: TabMenu
  /// The Battle Mode its tab shows now, which carries a checkmark.
  let selection: RotationMode
  /// Switches the tab to a Battle Mode.
  let choose: (RotationMode) -> Void

  var body: some View {
    let now = clock.now
    let terms = engine.snapshot.terms(in: language)

    VStack(spacing: 0) {
      ForEach(engine.snapshot.options(of: menu, at: now), id: \.mode) { option in
        Button { choose(option.mode) } label: {
          TabMenuRow(option: option, isSelected: option.mode == selection, terms: terms, now: now)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 6)
    // As wide as the widest row, so both rows share one width and the panel hugs the tab.
    .fixedSize(horizontal: true, vertical: false)
    // Regular glass in both colour schemes: the clear glass the adaptive effect uses on dark lets
    // the list show through the text.
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
  }
}

// MARK: - TabMenuRow

/// One option: the current Rule's icon (the Mode's while none plays), the Mode's name, its
/// summary line and a checkmark on the Battle Mode the tab shows.
private struct TabMenuRow: View {
  @TimeSettings private var time

  let option: TabMenuOption
  let isSelected: Bool
  let terms: GameTerms
  let now: Date

  var body: some View {
    HStack(spacing: 12) {
      Image(decorative: iconName, bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
        .frame(width: 32, height: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text(verbatim: option.mode.name(in: terms.language))
          .font(.headline)
        if let summary {
          Text(verbatim: summary)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 16)

      Image(systemName: "checkmark")
        .font(.body.weight(.semibold))
        .opacity(isSelected ? 1 : 0)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var iconName: String {
    if case .running(let running) = option.current, let setting = running.item.setting {
      return BundledImage.name(for: setting.rule, size: .small)
    }
    return BundledImage.name(for: ModeIcon(option.mode), size: .small)
  }

  /// The current Rule and time left, the pause with the return time, or nothing on; none before
  /// the Mode has a screen.
  private var summary: String? {
    let writer: SentenceWriter = time.writer(terms)
    switch option.current {
      case .running(let running):
        guard let setting = running.item.setting else { return writer.timeLeft(running.progress) }

        return "\(terms.name(of: setting.rule)) · \(writer.timeLeft(running.progress))"

      case .paused(let returnTime):
        let format = time.format(terms.language)
        return ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: now))

      case .nothingCurrent:
        return ScreenText.nothingCurrent.text(in: terms.language)

      case nil:
        return nil
    }
  }
}
