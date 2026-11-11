//
//  InkRuleName.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - InkRuleName

/// How a Rule's name is set in a later panel's narrow column: it may take two lines, but only
/// between words, never inside one.
enum InkRuleName {
  /// `name` on two lines, broken at the space nearest its middle ("Tower" over "Control"), or
  /// unchanged when it is one word. The break is written into the text, so a line that is still
  /// too wide can only shrink.
  static func balanced(_ name: String) -> String {
    let spaces: [String.Index] = name.indices.filter { name[$0] == " " }
    let middle: Int = name.count / 2
    guard
      let split = spaces.min(by: { lhs, rhs in
        abs(name.distance(from: name.startIndex, to: lhs) - middle)
          < abs(name.distance(from: name.startIndex, to: rhs) - middle)
      })
    else { return name }

    return name[..<split] + "\n" + name[name.index(after: split)...]
  }
}
