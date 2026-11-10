//
//  WatchShowcase.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import IkaCore
import IkaDesign
import IkaFixtures
import SwiftUI
import WidgetKit

// MARK: - WatchShowcase

/// The Debug launch's picture of the complications on a watch face (`--showcase complications`),
/// drawn by their own views from the snapshot at the app clock's instant: the simulator cannot
/// edit a face from a script, so the screenshot script captures this instead. A rebased fixture
/// launch keeps the system's countdowns on the fixture day.
enum WatchShowcase {
  /// Whether the launch asks for the complications' showcase.
  static func isRequested(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
    let option = "--showcase"
    let arguments: LaunchArguments = .init(arguments)
    guard arguments.contains(option) else { return false }
    guard arguments.value(of: option) == "complications" else {
      fatalError("\(option) takes complications on the watch")
    }

    return true
  }
}

// MARK: - ComplicationsShowcase

/// A watch face: the inline complication over the time, the rectangular one under it and three
/// circular ones along the bottom, on black.
struct ComplicationsShowcase: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now
    let terms = snapshot.terms(in: WatchServices.language)
    func entry(_ mode: Mode) -> ScheduleWidgetEntry<WatchWidgetContent> {
      ScheduleWidgetEntry(
        date: now,
        schedule: snapshot.watchWidgetTimeline(of: mode, from: now)?.entries.first,
        terms: terms)
    }

    return VStack(spacing: 4) {
      ModeComplicationLayout(entry: entry(.battle(.regular)), family: .accessoryInline)
        .lineLimit(1)
        .font(.system(size: 15, weight: .semibold))
      // The device's time, as the corner clock shows it: the watch simulator's status bar takes no
      // override.
      Text(Date(), format: .dateTime.hour().minute())
        .font(.system(size: 56, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .environment(\.timeZone, .autoupdatingCurrent)
      ModeComplicationLayout(entry: entry(.battle(.anarchySeries)), family: .accessoryRectangular)
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
      HStack(spacing: 8) {
        ForEach([Mode.battle(.x), .salmonRun, .battle(.anarchyOpen)], id: \.self) { mode in
          ModeComplicationLayout(entry: entry(mode), family: .accessoryCircular)
            .frame(width: 50, height: 50)
            .background(Circle().fill(.white.opacity(0.15)))
        }
      }
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 6)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
    .ignoresSafeArea()
    .toolbar(.hidden, for: .navigationBar)
  }
}
#endif
