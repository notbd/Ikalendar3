//
//  TrackingRender.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import ActivityKit
import Foundation
import IkaCore
import IkaDesign
import IkaIntents
import WidgetKit

extension TrackingRender {
  /// The render the system asks for with `context`, at the moment it draws.
  init(_ context: ActivityViewContext<TrackingAttributes>, at renderTime: Date = .now) {
    self.init(
      mode: context.attributes.mode,
      state: context.state,
      isStale: context.isStale,
      renderTime: renderTime,
      terms: WidgetData.trackingTerms())
  }
}

// MARK: - WidgetData

extension WidgetData {
  /// The game's names for a Live Activity's render, which cannot wait for a snapshot: the cached
  /// locale file of the app language, else the shipped snapshot.
  static func trackingTerms() -> GameTerms {
    guard let container = AppGroup.container() else { return Snapshot().terms(in: language) }

    return FeedCache(directory: AppGroup.feedDirectory(in: container)).terms(in: language)
  }
}
#endif
