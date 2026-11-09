//
//  WidgetParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import WidgetKit

// MARK: - WidgetText

/// The strings every widget extension writes itself, from `IkaDesign`'s `Widgets` string table.
/// The raw value is the catalog key. Names shown to the system (widget names, the configuration
/// intents) live in each extension's own table, where they are declared.
public enum WidgetText: String, CaseIterable, Sendable {
  /// "Schedule may be out of date": what the stale mark reads.
  case stale = "widget.stale"

  /// The string in a text set.
  public func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, table: "Widgets", in: language)
  }
}

// MARK: - ModeHeading

/// A Mode's icon and name over a widget's content or a column of it, with `trailing` at the far
/// end, such as how fresh the data is. VoiceOver reads it as one element.
public struct ModeHeading<Trailing: View>: View {
  let icon: ModeIcon
  let name: String
  let trailing: Trailing

  public init(icon: ModeIcon, name: String, @ViewBuilder trailing: () -> Trailing) {
    self.icon = icon
    self.name = name
    self.trailing = trailing()
  }

  public var body: some View {
    HStack(spacing: 6) {
      ModeIconImage(icon)
      Text(verbatim: name)
        .inkFont(.label)
        .scaledLimitedLine()
      Spacer(minLength: 0)
      trailing
    }
    .accessibilityElement(children: .combine)
  }
}

extension ModeHeading {
  /// The heading of a Rotation's Battle Mode.
  public init(mode: RotationMode, in language: GameLanguage, @ViewBuilder trailing: () -> Trailing) {
    self.init(icon: ModeIcon(mode), name: mode.name(in: language), trailing: trailing)
  }

  /// The heading of a Shift's kind: Salmon Run, Big Run or Eggstra Work.
  public init(kind: Shift.Kind, in language: GameLanguage, @ViewBuilder trailing: () -> Trailing) {
    self.init(icon: ModeIcon(kind), name: ModeLabel(kind).text(in: language), trailing: trailing)
  }
}

extension ModeHeading where Trailing == EmptyView {
  /// The heading of a Rotation's Battle Mode, with nothing at the far end.
  public init(mode: RotationMode, in language: GameLanguage) {
    self.init(mode: mode, in: language) { EmptyView() }
  }
}

// MARK: - FreshnessLabel

/// How fresh an entry's data is: when it was fetched, where `showsFetchTime` (sizes with room), and
/// in every size a mark while it is stale.
public struct FreshnessLabel<Content: Hashable & Sendable>: View {
  @Environment(\.gameLanguage) private var language
  @TimeSettings private var time

  let entry: WidgetEntry<Content>
  let showsFetchTime: Bool

  public init(entry: WidgetEntry<Content>, showsFetchTime: Bool) {
    self.entry = entry
    self.showsFetchTime = showsFetchTime
  }

  public var body: some View {
    HStack(spacing: 3) {
      if entry.isStale {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.yellow)
          .widgetAccentable()
          .accessibilityLabel(WidgetText.stale.text(in: language))
      }
      if showsFetchTime {
        let format = time.format(language)
        Text(verbatim: ScreenText.fetchTime.text(in: language, format.time(entry.fetchTime, relativeTo: entry.date)))
          .scaledLimitedLine()
      }
    }
    .font(.caption2)
    .foregroundStyle(.secondary)
  }
}

// MARK: - ModeIconImage

/// A Mode's bundled icon in its own colours, at `side` points scaled with the caption text size,
/// from the smallest pixel size that covers it. Decorative: the name beside it or the sentence
/// around it says the Mode.
public struct ModeIconImage: View {
  @Environment(\.displayScale) private var displayScale
  @ScaledMetric private var side: CGFloat

  private let icon: ModeIcon

  public init(_ icon: ModeIcon, side: CGFloat = 16) {
    self.icon = icon
    _side = ScaledMetric(wrappedValue: side, relativeTo: .caption)
  }

  public var body: some View {
    // The small icons are 64 pixels wide.
    let size: BundledImage.Size = side * displayScale > 64 ? .medium : .small
    Image(decorative: BundledImage.name(for: icon, size: size), bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
      .frame(width: side, height: side)
  }
}

// MARK: - PausedView

/// A Battle Mode a Splatfest pauses, with when it returns. VoiceOver reads its pause sentence.
public struct PausedView: View {
  @TimeSettings private var time

  let mode: BattleMode
  let returnTime: Date
  let date: Date
  let terms: GameTerms

  public init(mode: BattleMode, returnTime: Date, date: Date, terms: GameTerms) {
    self.mode = mode
    self.returnTime = returnTime
    self.date = date
    self.terms = terms
  }

  public var body: some View {
    let format = time.format(terms.language)
    Text(verbatim: ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: date)))
      .inkFont(.label)
      .scaledLimitedLine(lineLimit: 3)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(writer.sentence(forPauseOf: mode, returningAt: returnTime))
  }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - RuleLabel

/// A Rule's icon and name in `style`, the icon as tall as the text.
public struct RuleLabel: View {
  @ScaledMetric private var side: CGFloat

  private let rule: RuleID
  private let terms: GameTerms
  private let style: InkTextStyle

  public init(rule: RuleID, terms: GameTerms, style: InkTextStyle) {
    self.rule = rule
    self.terms = terms
    self.style = style
    _side = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
  }

  public var body: some View {
    HStack(spacing: 4) {
      Image(decorative: BundledImage.name(for: rule, size: .small), bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
        .frame(width: side, height: side)
      Text(verbatim: terms.name(of: rule))
        .inkFont(style)
        .scaledLimitedLine()
    }
  }
}
