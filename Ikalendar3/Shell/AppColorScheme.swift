//
//  AppColorScheme.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - AppColorScheme

/// Applies the colour scheme preference to every window of the app at once, as ikalendar 2 does:
/// the windows' interface style on iOS, the app's appearance on the Mac.
///
/// Not `preferredColorScheme(_:)`: when the preference returns to `nil` (Follow System), SwiftUI
/// keeps the last scheme on a view it presented, so Settings would stay dark while it is open.
@MainActor
enum AppColorScheme {
  /// How long the iOS windows cross-dissolve into the new scheme.
  static private let crossDissolve: TimeInterval = 0.25

  /// Applies `preference` to every window the app has open.
  static func apply(_ preference: ColorSchemePreference) {
    #if os(iOS)
    let windows = UIApplication.shared
      .connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
    for window in windows where window.overrideUserInterfaceStyle != preference.interfaceStyle {
      UIView.transition(with: window, duration: crossDissolve, options: .transitionCrossDissolve) {
        window.overrideUserInterfaceStyle = preference.interfaceStyle
      }
    }
    #else
    NSApplication.shared.appearance = preference.appearance
    #endif
  }
}

extension View {
  /// Applies the colour scheme preference to the app's windows now and on each change.
  func appColorScheme(_ preference: ColorSchemePreference) -> some View {
    onChange(of: preference, initial: true) { _, preference in
      AppColorScheme.apply(preference)
    }
  }
}

// MARK: - ColorSchemePreference

extension ColorSchemePreference {
  #if os(iOS)
  /// The windows' interface style: unspecified follows the system.
  fileprivate var interfaceStyle: UIUserInterfaceStyle {
    switch self {
      case .followSystem: .unspecified
      case .dark: .dark
      case .light: .light
    }
  }
  #else
  /// The app's appearance: `nil` follows the system.
  fileprivate var appearance: NSAppearance? {
    switch self {
      case .followSystem: nil
      case .dark: NSAppearance(named: .darkAqua)
      case .light: NSAppearance(named: .aqua)
    }
  }
  #endif
}
