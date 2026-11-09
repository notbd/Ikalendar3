//
//  TimeSettings.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import SwiftUI

extension EnvironmentValues {
  /// Whether Surfaces write times on a 12- or a 24-hour clock: the device's, unless a preview or
  /// test sets another. Views read it through `TimeSettings`.
  @Entry public var hourCycle: Locale.HourCycle = .device
}

extension Locale.HourCycle {
  /// The device's hour cycle, which its 24-Hour Time setting decides. The one place a Surface
  /// reads it.
  @usableFromInline static var device: Self { Locale.current.hourCycle }
}

// MARK: - TimeSettings

/// The time zone and hour cycle a view writes times in, from its environment: the device's,
/// unless a preview or test sets others. A view that writes a time or a sentence builds its
/// writer and formats here, so every Surface reads times as the device shows them.
///
/// ```swift
/// @TimeSettings private var time
///
/// var body: some View {
///   Text(verbatim: time.format(terms.language).timeRange(of: rotation))
///     .accessibilityLabel(time.writer(terms).sentence(for: rotation, at: now))
/// }
/// ```
@propertyWrapper
public struct TimeSettings: DynamicProperty {
  @Environment(\.timeZone) var timeZone
  @Environment(\.hourCycle) var hourCycle

  public init() { }

  public var wrappedValue: Self { self }

  /// The sentence writer in `terms`' text set.
  public func writer(_ terms: GameTerms) -> SentenceWriter {
    SentenceWriter(terms: terms, timeZone: timeZone, hourCycle: hourCycle)
  }

  /// How times are written in `language`.
  public func format(_ language: GameLanguage) -> ScheduleFormat {
    ScheduleFormat(language: language, timeZone: timeZone, hourCycle: hourCycle)
  }
}
