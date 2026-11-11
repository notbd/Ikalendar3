//
//  ClassicHeading.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicHeading

/// What heads a Classic screen: the Mode's name, with Anarchy Battle's or Splatfest Battle's form
/// under it, over the list, and the full name for the navigation bar. The name and form are the
/// ones Ink's heading shows (`InkModeHeading`), so every Style splits a name alike.
struct ClassicHeading: Equatable {
  /// The Mode's name: "Anarchy Battle".
  let name: String
  /// The form under the name, "Series", or `nil` for a Mode with one form.
  let form: String?
  /// The full name, for the navigation bar: "Anarchy Battle (Series)".
  let title: String

  /// The heading of `mode`.
  init(_ mode: Mode, in language: GameLanguage) {
    self.init(InkModeHeading(mode), title: mode.name(in: language), in: language)
  }

  /// The heading of Splatfest Battle in `form`, over the Splatfest screen.
  init(splatfestBattle form: SplatfestBattleForm, in language: GameLanguage) {
    self.init(
      InkModeHeading(splatfestBattle: form),
      title: RotationMode.splatfestBattle(form).name(in: language),
      in: language)
  }

  private init(_ heading: InkModeHeading, title: String, in language: GameLanguage) {
    name = heading.name.text(in: language)
    form = heading.form?.text(in: language)
    self.title = title
  }

  /// The heading over the Challenge screen.
  static func challenges(in language: GameLanguage) -> ClassicHeading {
    ClassicHeading(.challenges, title: ModeLabel.challenges.text(in: language), in: language)
  }
}

#if os(iOS)

// MARK: - ClassicHeadingView

/// The screen's name over a Classic list, where ikalendar 2 showed the navigation bar's large
/// title and in its face: the Mode's name and, for a Mode with forms, the form under it in the
/// secondary colour, as a large title's subtitle reads.
///
/// It leaves its trailing end to the Mode stamp, which hangs over it. Side by side, a name too
/// long for the rest shrinks to fit its line, as ikalendar 2's texts do, down to
/// `Heading.minimumScaleFactor`: the longest name of the 14 text sets ("Combate amistoso") needs
/// about 0.75 on a 390-point iPhone. From the first accessibility text size it wraps between
/// words instead, and stops growing there, as the system's large title does.
struct ClassicHeadingView: View {
  let heading: ClassicHeading
  let arrangement: CellArrangement

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(verbatim: heading.name)
        .font(.largeTitle.bold())
        // A colour, not the hierarchical style: a section header's text is secondary, and the
        // primary level inside it would resolve to that.
        .foregroundStyle(Color.primary)
        .lineLimit(arrangement == .sideBySide ? 1 : nil)
        .minimumScaleFactor(arrangement == .sideBySide ? ClassicMetrics.Heading.minimumScaleFactor : 1)
        .fixedSize(horizontal: false, vertical: true)
      if let form = heading.form {
        Text(verbatim: form)
          .font(.title3.weight(.semibold))
          .foregroundStyle(.classicSecondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.trailing, ClassicMetrics.Heading.stampClearance)
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    // From the section's edge, where ikalendar 2's large title began, rather than at the headers'
    // inset under it.
    .listRowInsets(EdgeInsets())
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }
}
#endif
#endif
