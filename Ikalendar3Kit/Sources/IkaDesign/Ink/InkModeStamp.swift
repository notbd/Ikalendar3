//
//  InkModeStamp.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

extension View {
  /// Hangs the Mode stamp, on a splat in `accent`, at the top-trailing corner of this scroll view and docks it into a
  /// glass badge in the navigation bar as the list scrolls, with ticket 12's stamp math: the
  /// stamp shrinks toward its corner and fades while the badge fades in, or only cross-fades under
  /// Reduce Motion. The bar's title, `title` in Ink's heavy face, fades in with the badge, since
  /// the heading in the list names the Mode at rest. A Mac window's toolbar is the window's, not a
  /// screen's, so there the stamp only shrinks and fades, as Classic's and Timeline's do.
  func inkModeStamp(icon: ModeIcon, accent: InkAccent, title: String) -> some View {
    modifier(InkModeStampDock(icon: icon, accent: accent, title: title))
  }
}

// MARK: - InkModeStampDock

/// The scroll tracking behind `inkModeStamp(icon:accent:title:)`, as ikalendar 2's tab view
/// tracks it.
private struct InkModeStampDock: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme

  let icon: ModeIcon
  let accent: InkAccent
  let title: String

  /// The share of the dock travel scrolled. The dock follows the finger with no easing, as the
  /// cross-fade does under Reduce Motion, measured from where the list rests rather than from
  /// the current top inset (`ModeStampMath.dockProgress(contentOffsetY:restingTopInset:)`).
  @State private var dockProgress: Double = 0
  /// The list's top content inset at rest, under the inline navigation bar.
  @State private var restingTopInset: CGFloat = 0
  /// How far the top inset has grown past rest: the pull-to-refresh spinner while a refresh runs.
  @State private var refreshTopInset: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .onScrollGeometryChange(for: CGFloat.self) { geometry in
        geometry.contentInsets.top
      } action: { _, topInset in
        // The smallest inset seen: the first layout can still carry the default large title
        // before the inline bar applies, and later insets grow by the pull-to-refresh spinner.
        restingTopInset = restingTopInset == 0 ? topInset : min(restingTopInset, topInset)
        refreshTopInset = topInset - restingTopInset
      }
      .onScrollGeometryChange(for: Double.self) { [restingTopInset] geometry in
        ModeStampMath.dockProgress(contentOffsetY: geometry.contentOffset.y, restingTopInset: restingTopInset)
      } action: { _, progress in
        dockProgress = progress
      }
      .overlay(alignment: .topTrailing) {
        InkModeStamp(
          icon: icon,
          accent: accent,
          style: ModeStampMath.dockStyle(progress: dockProgress, reduceMotion: reduceMotion))
          // While a refresh runs, the spinner's height is added to the safe area this overlay
          // hangs from, so the stamp is lifted by it to stay put.
          .offset(x: InkScreenMetrics.stampTrailingOverhang, y: -refreshTopInset)
          .allowsHitTesting(false)
      }
      #if os(iOS)
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(verbatim: title)
            .inkFont(.tag)
            .foregroundStyle(Color(InkPair.backgroundText.colors(in: colorScheme).foreground))
            .lineLimit(1)
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

/// The Mode's icon, turned, on a splat in the screen's accent: decoration, since the heading names
/// the Mode. The splat is a placeholder until ticket 51 draws the artwork.
private struct InkModeStamp: View {
  let icon: ModeIcon
  let accent: InkAccent
  let style: ModeStampMath.DockStyle

  var body: some View {
    ZStack {
      InkSplatPlaceholder()
        .fill(InkDecoration.splatShadow)
        .offset(x: 4, y: 6)
      InkSplatPlaceholder()
        .fill(Color(accent.base))
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

// MARK: - InkSplatPlaceholder

/// A round blob with a few soft lobes, standing in for the ink splat until ticket 51 draws it.
private struct InkSplatPlaceholder: Shape {
  /// The lobes: how many around the blob, how far they reach as a share of the radius, and where
  /// the first one points.
  private let lobes: [(count: Double, depth: Double, phase: Double)] = [(5, 0.08, 0.4), (3, 0.05, 1.7), (9, 0.025, 0.9)]
  /// The points along the outline.
  private let resolution: Int = 120

  func path(in rect: CGRect) -> Path {
    let radius: Double = .init(min(rect.width, rect.height)) / 2 / (1 + lobes.map(\.depth).reduce(0, +))
    var path: Path = .init()
    for index in 0 ... resolution {
      let angle: Double = .init(index) / Double(resolution) * 2 * .pi
      let reach: Double = radius * (1 + lobes.lazy.map { $0.depth * sin($0.count * angle + $0.phase) }.reduce(0, +))
      let point: CGPoint = .init(x: rect.midX + reach * cos(angle), y: rect.midY + reach * sin(angle))
      if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }
}
#endif
