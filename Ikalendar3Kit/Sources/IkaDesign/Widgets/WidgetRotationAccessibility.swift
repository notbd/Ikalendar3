//
//  WidgetRotationAccessibility.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - WidgetRotationAccessibility

/// What VoiceOver reads for a Rotation a widget shows, as one element: its sentence as the label,
/// with no time left, because the system draws a widget ahead of the moment VoiceOver reads it;
/// for the current Rotation, the system's countdown to its end as the value, which the system
/// keeps current. Every widget extension reads its Rotations through it.
public struct WidgetRotationAccessibility: Equatable, Sendable {
  /// The Rotation's sentence, with no time left.
  public let label: String
  /// The window the value counts down to its end, for the current Rotation; else `nil`.
  public let countdown: ClosedRange<Date>?

  /// How `rotation` reads, in `writer`'s text set; `isCurrent` for the Rotation on now.
  public init(_ rotation: Rotation, writer: SentenceWriter, isCurrent: Bool) {
    label = writer.sentence(for: rotation)
    countdown = isCurrent ? rotation.startTime ... rotation.endTime : nil
  }
}

extension View {
  /// Makes the view one VoiceOver element that reads a widget's Rotation, as
  /// `WidgetRotationAccessibility` says; `isCurrent` for the Rotation on now.
  public func widgetAccessibility(of rotation: Rotation, writer: SentenceWriter, isCurrent: Bool) -> some View {
    let reading: WidgetRotationAccessibility = .init(rotation, writer: writer, isCurrent: isCurrent)
    return accessibilityElement(children: .ignore)
      .accessibilityLabel(reading.label)
      .accessibilityValue(reading.countdown.map { Text(timerInterval: $0) } ?? Text(verbatim: ""))
  }
}
