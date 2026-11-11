//
//  TimelineHeader.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineHeader

/// SplatNet 3's black header where it leads the list, on iPad and Mac: the Mode stamp and the
/// Mode's name, centred. Its black runs on up behind the navigation bar and the pull-to-refresh
/// space, so the top reads as one header.
struct TimelineHeader: View {
  let icon: ModeIcon
  let name: String
  /// How far the stamp has docked into the navigation bar badge.
  let dockProgress: Double
  let arrangement: CellArrangement

  var body: some View {
    HStack(spacing: 9) {
      TimelineModeStamp(icon: icon, dockProgress: dockProgress)
      Text(verbatim: name)
        .ikaFont(.heavy, size: 19, relativeTo: .title3)
        .scaledLimitedLine(for: arrangement)
        .foregroundStyle(.white)
        .accessibilityAddTraits(.isHeader)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, minHeight: TimelineMetrics.headerHeight)
    .background(alignment: .bottom) {
      TimelinePalette.header
        .frame(height: Self.backdropHeight)
    }
  }

  /// How far the header's black reaches up past its top edge: beyond any navigation bar and
  /// pull-to-refresh space.
  static private let backdropHeight: CGFloat = 1000
}

// MARK: - TimelineBarTitle

/// The header as the navigation bar holds it at iPhone width: the Mode stamp and the Mode's name,
/// centred in the black bar.
struct TimelineBarTitle: View {
  let icon: ModeIcon
  let name: String

  var body: some View {
    HStack(spacing: 7) {
      Image(decorative: BundledImage.name(for: icon, size: .medium), bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
        .frame(width: TimelineMetrics.barStampSize, height: TimelineMetrics.barStampSize)
      Text(verbatim: name)
        .ikaFont(.heavy, size: 18, relativeTo: .headline)
        .scaledLimitedLine(lineLimit: 1, minScaleFactor: 0.6)
        .foregroundStyle(.white)
        .accessibilityAddTraits(.isHeader)
    }
    // A bar keeps its height, as the system's own titles do.
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }
}

// MARK: - TimelineModeStamp

/// A placeholder Mode stamp: the Mode's icon, until ticket 52 draws Timeline's form. As the list
/// scrolls it shrinks toward its top trailing corner and fades with ticket 12's stamp math; under
/// Reduce Motion it only fades.
private struct TimelineModeStamp: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let icon: ModeIcon
  let dockProgress: Double

  var body: some View {
    let style: ModeStampMath.DockStyle = ModeStampMath.dockStyle(progress: dockProgress, reduceMotion: reduceMotion)

    Image(decorative: BundledImage.name(for: icon, size: .large), bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
      .frame(width: TimelineMetrics.stampSize, height: TimelineMetrics.stampSize)
      .scaleEffect(style.scale, anchor: .topTrailing)
      .opacity(style.opacity)
  }
}

// MARK: - TimelineModeBadge

/// The 44 pt glass badge at the navigation bar's trailing end that the stamp docks into, as in
/// ikalendar 2. Decoration only: it takes no touches, and the title names the Mode.
struct TimelineModeBadge: View {
  let icon: ModeIcon

  var body: some View {
    Image(decorative: BundledImage.name(for: icon, size: .medium), bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
      .frame(width: TimelineMetrics.badgeImageSize, height: TimelineMetrics.badgeImageSize)
      .frame(width: TimelineMetrics.badgeSize, height: TimelineMetrics.badgeSize)
      .adaptiveGlassEffect(isInteractive: false, in: .circle)
  }
}

// MARK: - TimelineFormStrip

/// The strip of forms under the header, the form shown underlined in the Mode colour: Series and
/// Open on Anarchy, Open and Pro on Splatfest Battle. It shows which form the screen holds and
/// takes no tap: ticket 24's tab menu switches it. VoiceOver reads it as one text naming the shown
/// form, not as a selector.
struct TimelineFormStrip: View {
  /// Each form's label in the strip's order, and whether the screen shows it.
  let forms: [(label: ModeLabel, isShown: Bool)]
  /// The colour of the line under the shown form.
  let color: TimelineTint
  let language: GameLanguage

  /// Anarchy Battle's strip, `shown` being the form the screen shows.
  init(shown: BattleMode, language: GameLanguage) {
    forms = [(.series, shown == .anarchySeries), (.open, shown == .anarchyOpen)]
    color = .init(ModeColor(shown))
    self.language = language
  }

  /// Splatfest Battle's strip, `shown` being the form the screen shows, underlined in neutral.
  init(shown: SplatfestBattleForm, language: GameLanguage) {
    forms = [(.open, shown == .open), (.pro, shown == .pro)]
    color = .neutral
    self.language = language
  }

  var body: some View {
    HStack(spacing: 28) {
      ForEach(forms, id: \.label) { form in
        self.form(form.label, isShown: form.isShown)
      }
    }
    .frame(maxWidth: .infinity, minHeight: TimelineMetrics.stripHeight)
    // Only behind the strip: where it sits under the bar, the bar stays black.
    .background(TimelinePalette.strip, ignoresSafeAreaEdges: [])
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(verbatim: forms.first(where: \.isShown)?.label.text(in: language) ?? ""))
  }

  private func form(_ label: ModeLabel, isShown: Bool) -> some View {
    Text(verbatim: label.text(in: language))
      .ikaFont(.heavy, size: 14, relativeTo: .subheadline)
      .foregroundStyle(isShown ? .white : TimelinePalette.stripIdle)
      .padding(.vertical, 9)
      .overlay(alignment: .bottom) {
        if isShown {
          Rectangle()
            .fill(Color(color.base))
            .frame(height: TimelineMetrics.stripUnderline)
        }
      }
  }
}
#endif
