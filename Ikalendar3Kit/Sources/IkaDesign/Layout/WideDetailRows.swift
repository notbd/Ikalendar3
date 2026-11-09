//
//  WideDetailRows.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - WideRowHalves

/// The wide detail's current row in every Style: the label, Rule or Shift, progress and time
/// left in the leading half, the pictures in the trailing half, centred against each other.
struct WideRowHalves<Leading: View, Trailing: View>: View {
  let spacing: CGFloat
  @ViewBuilder let leading: Leading
  @ViewBuilder let trailing: Trailing

  var body: some View {
    HStack(alignment: .center, spacing: spacing) {
      leading
        .frame(maxWidth: .infinity, alignment: .leading)
      trailing
        .frame(maxWidth: .infinity)
    }
  }
}

// MARK: - WideTableColumns

/// A row of the wide detail's table in every Style, its columns lined up from row to row: the
/// time column takes what the fixed middle column (the Rule, or a Shift's Stage) and the
/// trailing pictures leave.
struct WideTableColumns<Time: View, Middle: View, Trailing: View>: View {
  let wide: WideDetailMetrics
  let spacing: CGFloat
  @ViewBuilder let time: Time
  @ViewBuilder let middle: Middle
  @ViewBuilder let trailing: Trailing

  var body: some View {
    HStack(alignment: .center, spacing: spacing) {
      VStack(alignment: .leading, spacing: spacing / 2) {
        time
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      middle
        .frame(width: wide.half.length(.tableRuleWidth), alignment: .leading)
      HStack(spacing: spacing / 2) {
        trailing
      }
    }
  }
}
