//
//  Shift+Label.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore

extension Shift.Kind {
  /// The label that marks a Big Run or an Eggstra Work among the Shifts, or `nil` for a regular
  /// Shift, which needs none.
  var label: ModeLabel? {
    switch self {
      case .regular: nil
      case .bigRun: .bigRun
      case .eggstraWork: .eggstraWork
    }
  }
}
