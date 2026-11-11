//
//  ClassicModeStamp.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import IkaCore
import SwiftUI

// MARK: - ClassicModeStampDock

/// ikalendar 2's tilted Mode stamp over the list's top trailing corner, which docks into a 44 pt
/// glass badge in the navigation bar as the list scrolls, with ticket 12's stamp math.
///
/// The screen's name heads the list itself (`ClassicHeadingView`) rather than the bar's large
/// title, which ran under the stamp when long, so the bar stays inline. Its title, the screen's
/// full name in the system's inline title font, fades in with the badge, as the large title
/// handed over to the inline one in ikalendar 2.
///
/// The dock progress is measured from where the list rests, not from the current top inset, as
/// ikalendar 2 deliberately does: the inset stays shrunk when a row above the viewport rolls off.
private struct ClassicModeStampDock: ViewModifier {
  let icon: ModeIcon
  /// The screen's full name, for the navigation bar.
  let title: String

  @State private var dockProgress: Double = 0
  /// The list's top content inset at rest under the inline navigation bar.
  @State private var restingTopInset: CGFloat = 0
  /// How far the top inset has grown past its resting value: the pull-to-refresh spinner's height
  /// while a refresh runs, 0 otherwise.
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
        ClassicModeStamp(icon: icon, dockProgress: dockProgress)
          // While a refresh runs, the spinner's height is added to the safe area this overlay
          // hangs from, so the stamp is lifted by it to stay put.
          .offset(x: ClassicMetrics.Stamp.offsetX, y: ClassicMetrics.Stamp.offsetY - refreshTopInset)
          .allowsHitTesting(false)
      }
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(verbatim: title)
            .font(.headline)
            // Shrunk to fit beside the bar's buttons rather than cut short, as Ink's title.
            .scaledLimitedLine()
            .opacity(ModeStampMath.badgeOpacity(progress: dockProgress))
        }
        ToolbarItem(placement: .topBarTrailing) {
          ClassicModeBadge(icon: icon)
            .opacity(ModeStampMath.badgeOpacity(progress: dockProgress))
            .allowsHitTesting(false)
        }
        // The badge draws its own glass, so the glass fades in with the badge.
        .sharedBackgroundVisibility(.hidden)
      }
  }
}

extension View {
  /// Hangs `icon`'s Mode stamp over this scroll view's top trailing corner and docks it into the
  /// navigation bar badge as the view scrolls, while `title` fades into the bar.
  func classicModeStamp(_ icon: ModeIcon, title: String) -> some View {
    modifier(ClassicModeStampDock(icon: icon, title: title))
  }
}

// MARK: - ClassicModeStamp

/// The Mode's icon, faded toward its bottom and tilted, swaying with the device. Docking shrinks
/// it toward its top trailing corner, fades it out and stills its tilt; under Reduce Motion it
/// keeps its resting pose, does not sway, and only fades.
private struct ClassicModeStamp: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase

  @State private var tilt: ModeStampMath.Tilt = .init(dx: 0, dy: 0)

  let icon: ModeIcon
  let dockProgress: Double

  var body: some View {
    let style: ModeStampMath.DockStyle = ModeStampMath.dockStyle(progress: dockProgress, reduceMotion: reduceMotion)
    let isTilting: Bool = DecorativeMotion.stampTilt.form(reduceMotion: reduceMotion) == .full
      && scenePhase == .active
      && style.opacity > 0

    ModeIconPicture(icon, size: .large)
      // The fade suits the game's one-piece icons. The Splatfest mark's drops, whose black outline
      // vanishes on the black ground, would read as three loose ones, so the mark stays whole.
      .mask(icon == .splatfestBattle ? Self.whole : Self.fade)
      .frame(width: ClassicMetrics.Stamp.size, height: ClassicMetrics.Stamp.size)
      // The resting tilt is a pose, not a motion: under Reduce Motion it stays while the stamp
      // fades, so the stamp looks the same; otherwise it eases out as the stamp docks.
      .rotationEffect(.degrees(ClassicMetrics.Stamp.rotationDegrees * (reduceMotion ? 1 : style.parallaxGain)))
      // Applied at 0 degrees rather than dropped when still, so the view keeps its identity.
      .rotation3DEffect(
        .degrees(ModeStampMath.rotationAngle(for: tilt, reduceMotion: reduceMotion) * style.parallaxGain),
        axis: (x: tilt.dy, y: tilt.dx, z: 0))
      .animation(.default, value: tilt)
      // After the tilt animation, so docking follows the scroll without easing.
      .scaleEffect(style.scale, anchor: .topTrailing)
      .opacity(style.opacity)
      .accessibilityHidden(true)
      .task(id: isTilting) {
        guard isTilting else {
          tilt = .init(dx: 0, dy: 0)
          return
        }

        for await sample in DeviceTilt.updates() {
          tilt = sample
        }
      }
  }

  /// The stamp's fade toward its bottom, built once because the body re-runs with every motion
  /// sample. Only the mask's opacity counts.
  static private let fade: LinearGradient = .init(
    colors: [1, 0.95, 0.9, 0.85, 0.8, 0.7, 0.4, 0.2, 0.1, 0.05, 0].map { Color.black.opacity($0) },
    startPoint: .top,
    endPoint: .bottom)

  /// No fade: the whole icon.
  static private let whole: LinearGradient = .init(colors: [.black], startPoint: .top, endPoint: .bottom)
}

// MARK: - ClassicModeBadge

/// The 44 pt glass badge at the navigation bar's trailing end that the stamp docks into: the
/// Mode's icon upright, like a toolbar icon. Decoration only: it takes no touches, and the
/// navigation title already names the Mode.
private struct ClassicModeBadge: View {
  let icon: ModeIcon

  var body: some View {
    ModeIconPicture(icon, size: .medium)
      .frame(width: ClassicMetrics.Stamp.badgeImageSize, height: ClassicMetrics.Stamp.badgeImageSize)
      .frame(width: ClassicMetrics.Stamp.badgeSize, height: ClassicMetrics.Stamp.badgeSize)
      .clipShape(.circle)
      .adaptiveGlassEffect(isInteractive: false, in: .circle)
      .accessibilityHidden(true)
  }
}
#endif
