//
//  InkBoard.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import SwiftUI

// MARK: - InkBoard

/// The board an Ink screen's panels lie on, as the game's Stages board holds its dark cards:
/// dotted black in dark appearance, the game's grey paper with darker dots in light appearance.
/// The panels are the same dark cards on both. Decoration, so VoiceOver skips it.
///
/// Widgets keep `InkBackground`, the dotted black, in both appearances.
struct InkBoard: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Color(InkPair.boardText.colors(in: colorScheme).background)
      .overlay {
        DotPattern(pitch: InkMetrics.backgroundDotPitch, radius: InkMetrics.backgroundDotRadius)
          .fill(InkDecoration.boardDot(in: colorScheme))
      }
      .accessibilityHidden(true)
  }
}

// MARK: - Previews

#Preview("Board") {
  VStack(spacing: 0) {
    ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
      InkBoard()
        .frame(height: 120)
        .environment(\.colorScheme, colorScheme)
    }
  }
}
#endif
