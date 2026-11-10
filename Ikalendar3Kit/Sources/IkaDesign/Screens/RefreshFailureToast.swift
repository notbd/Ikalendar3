//
//  RefreshFailureToast.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - RefreshFailureToast

/// The small glass toast that reports a failed refresh while the screen keeps its data. The
/// screen that shows it decides when it comes and goes.
public struct RefreshFailureToast: View {
  @Environment(\.gameLanguage) private var language

  public init() { }

  public var body: some View {
    Label {
      Text(verbatim: ScreenText.refreshFailed.text(in: language))
    } icon: {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.yellow)
    }
    .font(.subheadline.weight(.semibold))
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .adaptiveGlassEffect(isInteractive: false, in: .capsule)
    .accessibilityAddTraits(.isStaticText)
  }
}
