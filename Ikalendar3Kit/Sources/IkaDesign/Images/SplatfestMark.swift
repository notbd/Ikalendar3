//
//  SplatfestMark.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - SplatfestMark

/// The Splatfest's mark, which every Style shows where it shows Splatfest Battle's icon
/// (`ModeIconPicture`): three ink drops meeting at the centre, one per team in its colour, each
/// outlined in black with a shine, so each Splatfest has its own. With no team colours, as before
/// the feed names a Splatfest, the drops are three greys.
///
/// Drawn in code, square and fitted to its frame. Artwork for the mark replaces this body; its
/// callers pass only the colours.
public struct SplatfestMark: View {
  private let drops: Drops

  /// The mark in `teamColors`, in the feed's order: the top drop, then clockwise. Fewer than three
  /// colours give the grey mark.
  public init(teamColors: [SRGBColor]) {
    drops = teamColors.count >= Self.dropCount
      ? .colored(teamColors.prefix(Self.dropCount).map { Color($0) })
      : .colored(Self.neutralColors)
  }

  private init(drops: Drops) {
    self.drops = drops
  }

  /// The mark's silhouette in the foreground style, with no outline or shine, as a template image
  /// draws: for a tag that sets its icon in its text colour.
  static public let silhouette: SplatfestMark = .init(drops: .foreground)

  public var body: some View {
    Canvas { context, size in
      let side = min(size.width, size.height)
      let frame: CGRect = .init(
        x: (size.width - side) / 2,
        y: (size.height - side) / 2,
        width: side,
        height: side)
      let paths = (0 ..< Self.dropCount).map { Self.drop($0, in: frame) }

      switch drops {
        case .colored(let colors):
          // The outline is a stroke under the fills, so only its outer half shows.
          let outline: StrokeStyle = .init(lineWidth: side * Self.outlineWidth * 2, lineJoin: .round)
          for path in paths {
            context.stroke(path, with: .color(.black), style: outline)
          }
          for (index, (path, color)) in zip(paths, colors).enumerated() {
            context.fill(path, with: .color(color))
            context.fill(Self.shine(index, in: frame), with: .color(.white.opacity(0.9)))
          }

        case .foreground:
          for path in paths {
            context.fill(path, with: .foreground)
          }
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .accessibilityHidden(true)
  }
}

// MARK: Geometry

extension SplatfestMark {
  /// What fills the drops.
  private enum Drops {
    /// One colour per drop, outlined, with a shine.
    case colored([Color])
    /// The foreground style, as a silhouette.
    case foreground
  }

  /// One drop per team.
  static private let dropCount = 3

  /// The greys of the mark with no team colours: light, middle and dark, so it still reads as
  /// three drops in either appearance.
  static private let neutralColors: [Color] = [0xF2F2F2, 0xB4B4B8, 0x7C7C82].map { Color(SRGBColor(hex: $0)) }

  /// How far each drop's round end sits from the centre, as a share of the mark's side, as the
  /// lengths below are. Each drop is a circle with a point at the centre, and with its outline the
  /// mark stays inside its square: 0.25 + 0.19 + 0.03 < 0.5.
  static private let dropDistance: CGFloat = 0.25
  /// The radius of each drop's round end.
  static private let dropRadius: CGFloat = 0.19
  /// The black outline's width beyond each drop.
  static private let outlineWidth: CGFloat = 0.03

  /// The direction of drop `index` from the centre: up, then a third of a turn clockwise each.
  static private func direction(of index: Int) -> Double {
    -Double.pi / 2 + Double(index) * 2 * Double.pi / Double(dropCount)
  }

  /// Drop `index` in `frame`: its point at the centre, the two straight sides tangent to its round
  /// end, and the end's far arc between them.
  static private func drop(_ index: Int, in frame: CGRect) -> Path {
    let side = frame.width
    let direction = direction(of: index)
    let centre: CGPoint = .init(x: frame.midX, y: frame.midY)
    let end: CGPoint = .init(
      x: centre.x + cos(direction) * dropDistance * side,
      y: centre.y + sin(direction) * dropDistance * side)
    // The angle at the end's centre between the way back to the point and each tangent point.
    let tangent = acos(dropRadius / dropDistance)

    var path: Path = .init()
    path.move(to: centre)
    path.addRelativeArc(
      center: end,
      radius: dropRadius * side,
      startAngle: .radians(direction + .pi + tangent),
      delta: .radians(2 * .pi - 2 * tangent))
    path.closeSubpath()
    return path
  }

  /// The shine on drop `index`: a small round highlight toward the top leading side of its end.
  static private func shine(_ index: Int, in frame: CGRect) -> Path {
    let side = frame.width
    let direction = direction(of: index)
    let radius = dropRadius * side * 0.2
    let centre: CGPoint = .init(
      x: frame.midX + cos(direction) * dropDistance * side - dropRadius * side * 0.4,
      y: frame.midY + sin(direction) * dropDistance * side - dropRadius * side * 0.4)
    return Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
  }
}
