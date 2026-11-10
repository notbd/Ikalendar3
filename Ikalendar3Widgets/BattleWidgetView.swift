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
