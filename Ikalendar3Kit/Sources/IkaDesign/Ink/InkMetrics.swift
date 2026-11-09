//
//  InkMetrics.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

/// The fixed sizes of Ink's base components, from the round 3 mock and SplatNet 3's style sheet.
/// Sizes that follow a cell's width stay with the screens, in `CellMetrics`. Ticket 56 judges the
/// final values.
enum InkMetrics {
  // MARK: Tags

  /// How far a tag leans: the horizontal run per point of height (8 degrees).
  static let tagSlant: CGFloat = tan(8 * .pi / 180)
  /// The space beside a tag's text.
  static let tagHorizontalPadding: CGFloat = 9
  /// The space above and below a tag's text.
  static let tagVerticalPadding: CGFloat = 2

  // MARK: Panel

  /// The space between a panel's edge and its content.
  static let panelPadding: CGFloat = 14
  /// How far a rough edge strays from the straight line, at most.
  static let panelRoughness: CGFloat = 1.5
  /// The distance between the points of a rough edge.
  static let panelRoughStep: CGFloat = 6
  /// The corner radius of a panel's plain form.
  static let plainPanelCornerRadius: CGFloat = 12
  /// The strip of tape on the current panel.
  static let tapeSize: CGSize = .init(width: 84, height: 18)
  /// How far the tape is turned.
  static let tapeAngle: Angle = .degrees(-4)

  // MARK: Dots

  /// The distance between the background's dots.
  static let backgroundDotPitch: CGFloat = 14
  /// The radius of the background's dots.
  static let backgroundDotRadius: CGFloat = 1.4
  /// The distance between a dotted rule's dots.
  static let ruleDotPitch: CGFloat = 7
  /// The radius of a dotted rule's dots, half its height.
  static let ruleDotRadius: CGFloat = 1

  // MARK: Stage picture

  /// A Stage picture's width to height, the bundled images' own.
  static let pictureAspectRatio: CGFloat = 16 / 9
  /// SplatNet 3's corner radius on Stage pictures.
  static let pictureCornerRadius: CGFloat = 10
  /// The space between a picture's leading edge and its name tag.
  static let stageNameInset: CGFloat = 7
  /// The space between a picture and its name in the plain form, where the name sits below.
  static let plainStageNameSpacing: CGFloat = 3
}
