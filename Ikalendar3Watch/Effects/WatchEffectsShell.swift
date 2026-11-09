//
//  WatchEffectsShell.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import WidgetKit

// MARK: - WatchEffectsShell

/// The watch's one refresh run, as the app's `EffectsShell` is the app's: it refreshes under the
/// hourly gate, then applies the widget part of the effects plan `IkaCore` makes of the result to
/// the watch's complications and Smart Stack widget, deciding nothing itself. So the complications
/// reload after every refresh that committed a feed, a 304 included, and show the fetch time the
/// watch app shows.
///
/// The watch has no Live Activity or reminder of its own, so it applies no other part of the plan.
struct WatchEffectsShell {
  private let engine: RefreshEngine

  /// A shell that refreshes through an engine, whose snapshot the pages show.
  init(engine: RefreshEngine) {
    self.engine = engine
  }

  /// Refreshes under the hourly gate, then reloads the complications if the plan says so. A run
  /// that starts while another is in flight joins its refresh.
  @discardableResult
  func run() async -> RefreshResult {
    let result = await engine.refresh()
    if EffectsPlan(after: result, at: Date()).reloadsWidgetTimelines {
      WidgetCenter.shared.reloadAllTimelines()
    }
    return result
  }
}
