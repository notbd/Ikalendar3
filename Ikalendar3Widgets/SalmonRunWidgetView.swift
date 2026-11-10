//
//  SalmonRunWidgetView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI
import WidgetKit

// MARK: - SalmonRunWidgetView

/// The Salmon Run widget in Ink, in the size the system draws it at.
struct SalmonRunWidgetView: View {
  @Environment(\.widgetFamily) private var family

  let entry: ScheduleWidgetEntry<SalmonRunWidgetContent>

  var body: some View {
    SalmonRunWidgetLayout(entry: entry, family: family)
  }
}
