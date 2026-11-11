//
//  InkSplat.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import SwiftUI

// MARK: - InkSplat

/// A splat of ink in `color`, as large as it is offered: a round body with bumps around it and
/// fingers that end in a bulb, run together like wet ink, and a few loose droplets. Drawn in
/// code until ticket 51 supplies the artwork. Decoration, so VoiceOver skips it.
///
/// The blobs are circles blurred and then cut at half their opacity, which joins neighbours with
/// a rounded neck as ink does. The picture is fixed, so it is drawn once per size.
struct InkSplat: View, Equatable {
  let color: Color

  var body: some View {
    Canvas { context, size in
      let half: CGFloat = min(size.width, size.height) / 2
      let center: CGPoint = .init(x: size.width / 2, y: size.height / 2)

      var ink: GraphicsContext = context
      ink.addFilter(.alphaThreshold(min: 0.5, color: color))
      ink.addFilter(.blur(radius: half * Self.blur))
      ink.drawLayer { layer in
        for blob in Self.blobs {
          layer.fill(Path(ellipseIn: blob.rect(around: center, half: half)), with: .color(.white))
        }
      }
      for droplet in Self.droplets {
        context.fill(Path(ellipseIn: droplet.rect(around: center, half: half)), with: .color(color))
      }
    }
    .accessibilityHidden(true)
  }
}

extension InkSplat {
  /// A circle of the splat, in shares of half its size: where its centre lies from the splat's
  /// centre (the angle in degrees, clockwise from the trailing side) and its radius.
  private struct Blob {
    let angle: Double
    let distance: CGFloat
    let radius: CGFloat

    func rect(around center: CGPoint, half: CGFloat) -> CGRect {
      let radians: Double = angle * .pi / 180
      return CGRect(
        x: center.x + half * (distance * cos(radians) - radius),
        y: center.y + half * (distance * sin(radians) - radius),
        width: half * radius * 2,
        height: half * radius * 2)
    }
  }

  /// How far the blobs are blurred before the cut, as a share of half the splat's size: the
  /// width of the necks between them.
  static private let blur: CGFloat = 0.05

  /// The body, the bumps around it, then three fingers, each a neck and a bulb. The fingers point
  /// to the leading side and down, where the splat has room, and none points up at the bar.
  static private let blobs: [Blob] = [
    Blob(angle: 0, distance: 0, radius: 0.6),
    Blob(angle: -172, distance: 0.52, radius: 0.17),
    Blob(angle: -128, distance: 0.56, radius: 0.14),
    Blob(angle: -84, distance: 0.52, radius: 0.16),
    Blob(angle: -40, distance: 0.56, radius: 0.14),
    Blob(angle: 2, distance: 0.52, radius: 0.17),
    Blob(angle: 48, distance: 0.56, radius: 0.14),
    Blob(angle: 92, distance: 0.53, radius: 0.16),
    Blob(angle: 140, distance: 0.55, radius: 0.15),
    Blob(angle: -150, distance: 0.7, radius: 0.115),
    Blob(angle: -153, distance: 0.84, radius: 0.1),
    Blob(angle: 22, distance: 0.7, radius: 0.11),
    Blob(angle: 19, distance: 0.84, radius: 0.105),
    Blob(angle: 116, distance: 0.7, radius: 0.115),
    Blob(angle: 119, distance: 0.83, radius: 0.11),
    Blob(angle: 68, distance: 0.72, radius: 0.1),
  ]

  /// The loose droplets, drawn sharp so the cut keeps them.
  static private let droplets: [Blob] = [
    Blob(angle: -118, distance: 0.87, radius: 0.04),
    Blob(angle: 152, distance: 0.89, radius: 0.05),
    Blob(angle: 74, distance: 0.92, radius: 0.03),
    Blob(angle: -174, distance: 0.94, radius: 0.028),
  ]
}

// MARK: - Previews

#Preview("Splat") {
  InkPreviewGallery {
    HStack {
      InkSplat(color: Color(InkAccent(.regularBattle).base))
        .frame(width: 150, height: 150)
      InkSplat(color: Color(InkAccent(.anarchy).base))
        .frame(width: 90, height: 90)
    }
  }
}
#endif
