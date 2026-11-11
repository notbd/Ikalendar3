//
//  ModeIconPicture.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - ModeIconPicture

/// A Mode's icon, resizable and fitted to its frame: the bundled picture at a pixel size, or for
/// Splatfest Battle the Splatfest mark in the current Splatfest's team colours
/// (`splatfestTeamColors`). Every Style draws Mode icons through it, so the Splatfest shows the
/// same mark everywhere. Decorative: the name beside it says the Mode.
public struct ModeIconPicture: View {
  @Environment(\.splatfestTeamColors) private var teamColors

  private let icon: ModeIcon
  private let size: BundledImage.Size
  private let renderingMode: Image.TemplateRenderingMode

  /// - Parameters:
  ///   - icon: The icon.
  ///   - size: The bundled picture's pixel size.
  ///   - renderingMode: `.template` draws the icon's silhouette in the foreground style.
  public init(_ icon: ModeIcon, size: BundledImage.Size, renderingMode: Image.TemplateRenderingMode = .original) {
    self.icon = icon
    self.size = size
    self.renderingMode = renderingMode
  }

  public var body: some View {
    switch (icon, renderingMode) {
      case (.splatfestBattle, .template):
        SplatfestMark.silhouette
      case (.splatfestBattle, _):
        SplatfestMark(teamColors: teamColors)
      default:
        Image(decorative: BundledImage.name(for: icon, size: size), bundle: BundledImage.catalogBundle)
          .renderingMode(renderingMode)
          .resizable()
          .interpolation(.high)
          .antialiased(true)
          .scaledToFit()
    }
  }
}

extension EnvironmentValues {
  /// The current Splatfest's team colours, in the feed's order, which the Splatfest mark draws:
  /// empty while no Splatfest is known, for the grey mark. The app sets it from its snapshot.
  @Entry public var splatfestTeamColors: [SRGBColor] = []
}
