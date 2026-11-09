//
//  TrackingAttributes.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import ActivityKit
import Foundation
import IkaCore

// MARK: - TrackingAttributes

/// The Live Activity of Tracking one Mode. The app starts and updates it through the effects
/// shell; the widget extension draws it. Both link this module, so it is declared here.
///
/// Its content state is `IkaCore`'s plain value, ids and times only, far under ActivityKit's 4 KB.
public struct TrackingAttributes: ActivityAttributes {
  public typealias ContentState = TrackingState

  /// The tracked Mode.
  public let mode: Mode
  /// When Tracking started.
  public let startTime: Date

  public init(mode: Mode, startTime: Date) {
    self.mode = mode
    self.startTime = startTime
  }
}
#endif
