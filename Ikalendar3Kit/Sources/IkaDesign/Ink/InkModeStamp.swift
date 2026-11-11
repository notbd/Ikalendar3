//
//  InkModeStamp.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

extension EnvironmentValues {
  /// The share of the dock travel an Ink list has scrolled: 0 at rest, 1 once its Mode stamp has
  /// docked into the navigation bar badge. `inkModeStampDock(icon:title:)` sets it for the list
  /// and the stamp in the heading reads it, so scrolling redraws the stamp and nothing else.
  @Entry var inkStampDockProgress: Double = 0
}

extension View {
  /// Docks the Mode stamp in this scroll view's heading into a glass badge in the navigation bar
  /// as the list scrolls, with ticket 12's stamp math: the stamp shrinks toward its corner and
  /// fades while the badge fades in, or only cross-fades under Reduce Motion. The bar's title,
  /// `title` in Ink's heavy face, fades in with the badge, since the heading in the list names
  /// the Mode at rest. A Mac window's toolbar is the window's, not a screen's, so there the stamp
  /// only shrinks and fades, as Classic's and Timeline's do.
  func inkModeStampDock(icon: ModeIcon, title: String) -> some View {
    modifier(InkModeStampDock(icon: icon, title: title))
  }
}

// MARK: - InkModeStampDock

/// The scroll tracking behind `inkModeStampDock(icon:title:)`, as ikalendar 2's tab view tracks
/// it.
private struct InkModeStampDock: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  let icon: ModeIcon
  let title: String

  /// The share of the dock travel scrolled. The dock follows the finger with no easing, as the
  /// cross-fade does under Reduce Motion, measured from where the list rests rather than from
  /// the current top inset (`ModeStampMath.dockProgress(contentOffsetY:restingTopInset:)`).
  @State private var dockProgress: Double = 0
  /// The list's top content inset at rest, under the inline navigation bar.
  @State private var restingTopInset: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .environment(\.inkStampDockProgress, dockProgress)
      .onScrollGeometryChange(for: CGFloat.self) { geometry in
        geometry.contentInsets.top
      } action: { _, topInset in
        // The smallest inset seen: the first layout can still carry the default large title
        // before the inline bar applies, and later insets grow by the pull-to-refresh spinner.
        restingTopInset = restingTopInset == 0 ? topInset : min(restingTopInset, topInset)
      }
      .onScrollGeometryChange(for: Double.self) { [restingTopInset] geometry in
        ModeStampMath.dockProgress(contentOffsetY: geometry.contentOffset.y, restingTopInset: restingTopInset)
      } action: { _, progress in
        dockProgress = progress
      }
      #if os(iOS)
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(verbatim: title)
            .inkFont(.tag)
            .foregroundStyle(Color(InkPair.boardText.colors(in: colorScheme).foreground))
            // Beside the bar's buttons a long name, such as Anarchy Battle (Series), shrinks
            // rather than loses its form.
            .scaledLimitedLine()
            .opacity(badgeOpacity)
        }
        ToolbarItem(placement: .primaryAction) {
          InkModeBadge(icon: icon)
            .opacity(badgeOpacity)
            .allowsHitTesting(false)
        }
        // The badge draws its own glass, so the glass fades in with the badge.
        .sharedBackgroundVisibility(.hidden)
      }
      #endif
  }

  /// How far the badge and the bar's title have faded in.
  private var badgeOpacity: Double {
    ModeStampMath.badgeOpacity(progress: dockProgress)
  }
}

// MARK: - InkModeStamp

/// The Mode's icon, turned, on a splat in the screen's accent, in the list's heading: decoration,
/// since the heading names the Mode. It scrolls with the list and shrinks toward its top-trailing
/// corner and fades on the way, as the list's dock progress says.
struct InkModeStamp: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.inkStampDockProgress) private var dockProgress

  let icon: ModeIcon
  let accent: InkAccent

  var body: some View {
    let style: ModeStampMath.DockStyle = ModeStampMath.dockStyle(progress: dockProgress, reduceMotion: reduceMotion)

    ZStack {
      InkSplat(color: InkDecoration.splatShadow)
        .equatable()
        .offset(InkScreenMetrics.splatShadowOffset)
      InkSplat(color: Color(accent.base))
        .equatable()
      ZStack {
        // A black outline, so an icon in the splat's own colour (Salmon Run's) still stands out.
        ForEach(Self.outlineOffsets, id: \.self) { offset in
          ModeIconPicture(icon, size: .large, renderingMode: .template)
            .scaledToFit()
            .foregroundStyle(.black)
            .offset(offset)
        }
        iconImage
          .scaledToFit()
      }
      .frame(width: InkScreenMetrics.stampIconSize, height: InkScreenMetrics.stampIconSize)
      .shadow(color: InkDecoration.splatShadow, radius: 4, y: 3)
      .rotationEffect(InkScreenMetrics.stampAngle * style.parallaxGain)
    }
    .frame(width: InkScreenMetrics.splatSize, height: InkScreenMetrics.splatSize)
    .scaleEffect(style.scale, anchor: .topTrailing)
    .opacity(style.opacity)
    .accessibilityHidden(true)
  }
}

extension InkModeStamp {
  /// The icon's eight copies that make its outline, each shifted by the outline's width.
  static private let outlineOffsets: [CGSize] = (0 ..< 8).map { step in
    let angle: Double = .init(step) * .pi / 4
    return CGSize(
      width: cos(angle) * InkScreenMetrics.stampOutlineWidth,
      height: sin(angle) * InkScreenMetrics.stampOutlineWidth)
  }

  private var iconImage: ModeIconPicture {
    ModeIconPicture(icon, size: .large)
  }
}

// MARK: - InkModeBadge

/// The navigation bar badge the stamp docks into: the Mode's icon upright in a circle of
/// non-interactive glass. Decoration, since the bar's title names the Mode.
private struct InkModeBadge: View {
  let icon: ModeIcon

  var body: some View {
    ModeIconPicture(icon, size: .medium)
      .frame(width: InkScreenMetrics.badgeIconSize, height: InkScreenMetrics.badgeIconSize)
      .frame(width: InkScreenMetrics.badgeSize, height: InkScreenMetrics.badgeSize)
      .clipShape(.circle)
      .adaptiveGlassEffect(isInteractive: false, in: .circle)
      .accessibilityHidden(true)
  }
}
#endif
