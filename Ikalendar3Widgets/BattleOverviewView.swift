//
//  BattleOverviewView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI
import WidgetKit

// MARK: - BattleOverviewView

/// The extra large widget in Ink: a column for each continuous Battle Mode with its current
/// Rotation, or its pause, and how fresh the data is, on Ink's dotted background.
struct BattleOverviewView: View {
  let entry: ScheduleWidgetEntry<[BattleWidgetContent]>

  var body: some View {
    Group {
      if let schedule = entry.schedule {
        VStack(spacing: 10) {
          HStack(alignment: .top, spacing: 14) {
            ForEach(schedule.content, id: \.mode) { content in
              VStack(alignment: .leading, spacing: 8) {
                ModeHeading(mode: content.shownMode, in: entry.terms.language)
                CurrentView(
                  current: content.current,
                  mode: content.mode,
                  date: schedule.date,
                  terms: entry.terms,
                  stageAxis: .vertical,
                  ruleStyle: .tag)
              }
              .frame(maxWidth: .infinity, alignment: .topLeading)
            }
          }
          Spacer(minLength: 0)
          FreshnessLabel(entry: schedule, showsFetchTime: true)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
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
}
