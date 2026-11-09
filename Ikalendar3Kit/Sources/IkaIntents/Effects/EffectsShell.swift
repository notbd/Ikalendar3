//
//  EffectsShell.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import WidgetKit

// MARK: - EffectsShell

/// The one run every entry point makes: the app on activation, on a manual refresh and from its
/// background task, and the intents that refresh, directly. A run refreshes under the hourly gate,
/// then applies the effects plan `IkaCore` makes of the result, deciding nothing itself. So a run
/// that commits new data applies every effect, whichever entry point started it.
@MainActor
public struct EffectsShell {
  private let engine: RefreshEngine

  /// A shell that refreshes through an engine, whose snapshot the caller shows.
  public init(engine: RefreshEngine) {
    self.engine = engine
  }

  /// Refreshes under the hourly gate, then applies the effects the result calls for. A run that
  /// starts while another is in flight joins its refresh.
  @discardableResult
  public func run() async -> RefreshResult {
    let result = await engine.refresh()
    apply(EffectsPlan(after: result))
    return result
  }

  private func apply(_ plan: EffectsPlan) {
    if plan.reloadsWidgetTimelines {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}
