//
//  InterfaceOrientation.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import UIKit
#endif

// MARK: - InterfaceOrientation

/// The interface's orientation, as a plain input to the stamp's tilt math on every platform.
public enum InterfaceOrientation: CaseIterable, Sendable {
  /// Not known yet.
  case unknown
  /// Home indicator at the bottom.
  case portrait
  /// Home indicator at the top.
  case portraitUpsideDown
  /// Home indicator on the left.
  case landscapeLeft
  /// Home indicator on the right.
  case landscapeRight
}

#if os(iOS)
extension InterfaceOrientation {
  /// The orientation UIKit reports.
  public init(_ orientation: UIInterfaceOrientation) {
    switch orientation {
      case .portrait: self = .portrait
      case .portraitUpsideDown: self = .portraitUpsideDown
      case .landscapeLeft: self = .landscapeLeft
      case .landscapeRight: self = .landscapeRight
      case .unknown: self = .unknown
      @unknown default: self = .unknown
    }
  }
}
#endif
