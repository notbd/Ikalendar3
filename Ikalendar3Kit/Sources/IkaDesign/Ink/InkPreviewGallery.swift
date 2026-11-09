//
//  InkPreviewGallery.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import WidgetKit

/// Shows an Ink component's sample in dark and light appearance on the dotted background, and in
/// the plain form of the vibrant widget rendering mode, on black standing in for a Lock Screen
/// wallpaper. Previews only; not behind `#if DEBUG`,
/// because Release builds type-check `#Preview` bodies too.
struct InkPreviewGallery<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 0) {
      sample(colorScheme: .dark, renderingMode: .fullColor)
      sample(colorScheme: .light, renderingMode: .fullColor)
      sample(colorScheme: .dark, renderingMode: .vibrant)
    }
  }

  private func sample(colorScheme: ColorScheme, renderingMode: WidgetRenderingMode) -> some View {
    content
      .padding(24)
      .frame(maxWidth: .infinity)
      .background { InkBackground() }
      .background(.black)
      .environment(\.colorScheme, colorScheme)
      .environment(\.widgetRenderingMode, renderingMode)
  }
}
