//
//  AppIconMark.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - AppIconMark

/// The app's icon as the welcome screen and the About header draw it. A stand-in shape until the
/// app icon is decided (ticket 60), which replaces this view's body with the icon's image.
struct AppIconMark: View {
  /// The side length in points.
  let size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
      .fill(Color(.appAccent).gradient)
      .overlay {
        Image(systemName: "calendar")
          .font(.system(size: size * 0.5, weight: .semibold))
          .foregroundStyle(.white)
      }
      .frame(width: size, height: size)
      .shadow(radius: 2)
      .accessibilityHidden(true)
  }
}
