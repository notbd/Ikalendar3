//
//  BattleWidgetView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI
import WidgetKit

// MARK: - BattleWidgetView

/// The battle widget in Ink, in the size or Lock Screen family the system draws it at.
struct BattleWidgetView: View {
  @Environment(\.widgetFamily) private var family

  let entry: ScheduleWidgetEntry<BattleWidgetContent>

  var body: some View {
    switch family {
      #if os(iOS)
      case .accessoryCircular,
             .accessoryRectangular,
             .accessoryInline:
        LockScreenBattleView(entry: entry, family: family)
      #endif
      default:
        BattleWidgetLayout(entry: entry, family: family)
    }
  }
}

// MARK: - BattleWidgetLayout

/// The battle widget in Ink at `family`: the Battle Mode it shows (Splatfest Battle while one
/// replaces it), the current Rotation and, by size, the next one or the next four, on Ink's
/// dotted background.
struct BattleWidgetLayout: View {
  let entry: ScheduleWidgetEntry<BattleWidgetContent>
  let family: WidgetFamily

  var body: some View {
    Group {
      if let schedule = entry.schedule {
        content(schedule)
      }
      else {
        EmptyWidgetView()
      }
    }
    .environment(\.gameLanguage, entry.terms.language)
    .containerBackground(for: .widget) {
      InkBackground()
    }
  }

  private func content(_ schedule: WidgetEntry<BattleWidgetContent>) -> some View {
    let content = schedule.content
    let current: CurrentView = .init(
      current: content.current,
      mode: content.mode,
      date: schedule.date,
      terms: entry.terms)

    return VStack(alignment: .leading, spacing: 8) {
      ModeHeading(mode: content.shownMode, in: entry.terms.language) {
        FreshnessLabel(entry: schedule, showsFetchTime: family != .systemSmall)
      }
      switch family {
        case .systemMedium:
          HStack(alignment: .top, spacing: 12) {
            current
              .frame(maxWidth: .infinity, alignment: .leading)
            if let next = content.upcoming.first {
              RotationView(rotation: next, terms: entry.terms)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }

        case .systemLarge:
          current
            .layoutPriority(1)
          VStack(alignment: .leading, spacing: 5) {
            ForEach(content.upcoming, id: \.self) { rotation in
              InkDottedRule()
              RotationRow(rotation: rotation, terms: entry.terms, shownMode: content.shownMode)
            }
          }

        default:
          current
      }
      Spacer(minLength: 0)
    }
  }
}
