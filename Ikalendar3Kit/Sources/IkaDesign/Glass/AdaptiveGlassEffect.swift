//
//  AdaptiveGlassEffect.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - AdaptiveGlassVariant

/// The glass the adaptive glass effect uses in a colour scheme.
public enum AdaptiveGlassVariant: Sendable {
  /// Regular glass, on light.
  case regular
  /// Clear glass, on dark, where regular glass washes out.
  case clear

  /// The variant for `colorScheme`.
  public init(colorScheme: ColorScheme) {
    self = colorScheme == .dark ? .clear : .regular
  }

  /// The system glass for this variant.
  var glass: Glass {
    switch self {
      case .regular: .regular
      case .clear: .clear
    }
  }
}

// MARK: - AdaptiveGlassEffect

/// A glass effect, interactive unless told otherwise, that adapts to the colour scheme.
///
/// Increase Contrast and Reduce Transparency are left to the system's own glass fallbacks: the
/// effect reads neither setting and overrides nothing.
private struct AdaptiveGlassEffect<EffectShape: Shape>: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  let tint: Color?
  let isInteractive: Bool
  let shape: EffectShape

  func body(content: Content) -> some View {
    let baseGlass: Glass = AdaptiveGlassVariant(colorScheme: colorScheme).glass
    let tintedGlass: Glass = tint.map { baseGlass.tint($0) } ?? baseGlass

    content
      .glassEffect(tintedGlass.interactive(isInteractive), in: shape)
  }
}

extension View {
  /// Applies a colour-scheme-aware glass effect in `shape`, interactive by default. Pass
  /// `isInteractive: false` for glass that only decorates, such as a badge.
  public func adaptiveGlassEffect(
    tint: Color? = nil,
    isInteractive: Bool = true,
    in shape: some Shape)
    -> some View
  {
    modifier(AdaptiveGlassEffect(tint: tint, isInteractive: isInteractive, shape: shape))
  }
}
