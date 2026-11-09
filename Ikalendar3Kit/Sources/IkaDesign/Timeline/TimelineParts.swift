//
//  TimelineParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineRotationContent

/// A Rotation's slot: its Rule, "Now" with the countdown while it runs, and both Stage pictures
/// joined in one strip.
struct TimelineRotationContent: View {
  let setting: Rotation.Setting
  let progress: WindowProgress?
  let color: ModeColor
  let terms: GameTerms
  let now: Date
  let arrangement: CellArrangement

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      TimelineHeadline(arrangement: arrangement) {
        HStack(spacing: 8) {
          Image(decorative: BundledImage.name(for: setting.rule, size: .medium), bundle: BundledImage.catalogBundle)
            .resizable()
            .scaledToFit()
            .frame(width: TimelineMetrics.ruleIconSize, height: TimelineMetrics.ruleIconSize)
          Text(verbatim: terms.name(of: setting.rule))
            .ikaFont(.heavy, size: 18, relativeTo: .headline)
            .scaledLimitedLine(for: arrangement)
            .foregroundStyle(.white)
        }
      } trailing: {
        if let progress {
          TimelineNowTag(timeLeft: progress.timeLeft, color: color, language: terms.language, now: now)
        }
      }
      TimelineStageStrip(stages: setting.stages, terms: terms, arrangement: arrangement)
    }
  }
}

// MARK: - TimelineShiftContent

/// A Shift's slot: a Big Run or Eggstra Work tag, its time range and "Now" with the countdown
/// while it runs, the Stage picture, then the four weapons and the King Salmonid.
struct TimelineShiftContent: View {
  let shift: Shift
  let progress: WindowProgress?
  let terms: GameTerms
  let format: TimelineFormat
  let now: Date
  let arrangement: CellArrangement

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let label = shift.kind.label {
        TimelineKindTag(label: label, kind: shift.kind, language: terms.language)
      }
      TimelineHeadline(arrangement: arrangement) {
        Text(verbatim: format.timeRange(from: shift.startTime, to: shift.endTime))
          .ikaFont(.light, size: 14, relativeTo: .subheadline)
          .scaledLimitedLine(for: arrangement)
          .foregroundStyle(.white)
      } trailing: {
        if let progress {
          TimelineNowTag(timeLeft: progress.timeLeft, color: ModeColor(shift.kind), language: terms.language, now: now)
        }
      }
      TimelineStageStrip(stages: [shift.stage], terms: terms, arrangement: arrangement)
      TimelineWeapons(weapons: shift.weapons, kingSalmonid: shift.kingSalmonid, terms: terms)
    }
  }
}

// MARK: - TimelineStatusContent

/// Why no Rotation or Shift is on: paused until a return time, or nothing current.
struct TimelineStatusContent: View {
  let text: String

  var body: some View {
    Text(verbatim: text)
      .ikaFont(.light, size: 16, relativeTo: .body)
      .foregroundStyle(.white)
      .fixedSize(horizontal: false, vertical: true)
  }
}

// MARK: - TimelineHeadline

/// A slot's first line: the leading part, with the trailing part at the far end side by side, or
/// under it when stacked.
private struct TimelineHeadline<Leading: View, Trailing: View>: View {
  let arrangement: CellArrangement
  @ViewBuilder let leading: Leading
  @ViewBuilder let trailing: Trailing

  var body: some View {
    switch arrangement {
      case .sideBySide:
        HStack(spacing: 8) {
          leading
          Spacer(minLength: 0)
          trailing
        }

      case .stacked:
        VStack(alignment: .leading, spacing: 4) {
          leading
          trailing
        }
    }
  }
}

// MARK: - TimelineNowTag

/// "Now" in the Mode colour, with the time left counting down on whole seconds.
struct TimelineNowTag: View {
  @Environment(\.colorScheme) private var colorScheme

  let timeLeft: Duration
  let color: ModeColor
  let language: GameLanguage
  let now: Date

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text(verbatim: TimelineText.now.text(in: language))
        .ikaFont(.heavy, size: 13, relativeTo: .footnote)
        .foregroundStyle(Color(color.onPanel(of: .timeline, in: colorScheme, for: .text).foreground))
      Text(verbatim: TimelineText.timeLeft.text(in: language, TimelineFormat.countdown(timeLeft)))
        .ikaFont(.light, size: 12, relativeTo: .caption)
        .monospacedDigit()
        .foregroundStyle(TimelinePalette.secondaryText)
        .countdownRoll(value: now)
    }
    .lineLimit(1)
    .fixedSize()
  }
}

// MARK: - TimelineKindTag

/// The mark of a Big Run or an Eggstra Work: its icon and label on a tag in its colour.
struct TimelineKindTag: View {
  let label: ModeLabel
  let kind: Shift.Kind
  let language: GameLanguage

  var body: some View {
    let colors: ColorPair = ModeColor(kind).asFill

    HStack(spacing: 4) {
      // In the tag's text colour: the icon's own colour is the tag's.
      Image(decorative: BundledImage.name(for: ModeIcon(kind), size: .small), bundle: BundledImage.catalogBundle)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
      Text(verbatim: label.text(in: language))
        .ikaFont(.heavy, size: 13, relativeTo: .footnote)
        .lineLimit(1)
    }
    .foregroundStyle(Color(colors.foreground))
    .padding(.horizontal, 7)
    .padding(.vertical, 2)
    .background(Color(colors.background), in: .rect(cornerRadius: TimelineMetrics.pinCornerRadius))
    .fixedSize()
  }
}

// MARK: - TimelineStageStrip

/// Stage pictures joined in one strip with rounded outer corners, each name on a black tag
/// centred at its bottom. Stacked, the pictures run one under the other and the names wrap below
/// them.
struct TimelineStageStrip: View {
  let stages: [StageID]
  let terms: GameTerms
  let arrangement: CellArrangement

  var body: some View {
    let layout: AnyLayout = arrangement == .stacked
      ? AnyLayout(VStackLayout(spacing: TimelineMetrics.pictureGap))
      : AnyLayout(HStackLayout(spacing: TimelineMetrics.pictureGap))

    layout {
      ForEach(Array(stages.enumerated()), id: \.offset) { _, stage in
        TimelineStagePicture(stage: stage, name: terms.name(of: stage), arrangement: arrangement)
      }
    }
    .background(.black)
    .clipShape(.rect(cornerRadius: TimelineMetrics.pictureCornerRadius))
  }
}

// MARK: - TimelineStagePicture

/// One Stage's picture with its name. The picture is decorative: the slot's sentence names the
/// Stage.
private struct TimelineStagePicture: View {
  let stage: StageID
  let name: String
  let arrangement: CellArrangement

  var body: some View {
    switch arrangement {
      case .sideBySide:
        picture
          .overlay(alignment: .bottom) {
            nameTag
              .padding(.horizontal, 4)
              .padding(.bottom, 5)
          }

      case .stacked:
        VStack(spacing: 0) {
          picture
          nameTag
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
  }

  private var picture: some View {
    Color.clear
      .aspectRatio(TimelineMetrics.pictureAspectRatio, contentMode: .fit)
      .overlay {
        Image(decorative: BundledImage.name(for: stage, size: .large), bundle: BundledImage.catalogBundle)
          .resizable()
          .scaledToFill()
      }
      .clipped()
  }

  private var nameTag: some View {
    Text(verbatim: name)
      .ikaFont(.light, size: 12, relativeTo: .caption)
      .scaledLimitedLine(for: arrangement)
      .multilineTextAlignment(.center)
      .foregroundStyle(.white)
      .padding(.horizontal, 7)
      .background(.black)
  }
}

// MARK: - TimelineWeapons

/// A Shift's four weapons on a black plate, random marks drawn as the game's question marks, and
/// the King Salmonid at the far end. Each picture carries its name.
struct TimelineWeapons: View {
  let weapons: [WeaponID]
  let kingSalmonid: KingSalmonidID?
  let terms: GameTerms

  var body: some View {
    HStack(spacing: 6) {
      HStack(spacing: 4) {
        ForEach(Array(weapons.enumerated()), id: \.offset) { _, weapon in
          picture(BundledImage.name(for: weapon, size: .medium), label: terms.name(of: weapon))
        }
      }
      .padding(4)
      .background(.black, in: .capsule)
      Spacer(minLength: 0)
      if let kingSalmonid {
        picture(BundledImage.name(for: kingSalmonid, size: .medium), label: terms.name(of: kingSalmonid))
          .padding(4)
          .background(.black, in: .circle)
      }
    }
  }

  private func picture(_ name: String, label: String) -> some View {
    Image(name, bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
      .frame(maxWidth: TimelineMetrics.weaponSize, maxHeight: TimelineMetrics.weaponSize)
      .accessibilityLabel(Text(verbatim: label))
  }
}
#endif
