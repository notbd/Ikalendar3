//
//  ClassicShiftCell.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicShiftSection

/// One Shift's row of Classic's Salmon Run list, as ikalendar 2's `SalmonRotationRow` draws it:
/// a header with its tag and kind when it has either, over the Shift's cell.
struct ClassicShiftSection: View {
  @TimeSettings private var time

  let shift: Shift
  let progress: WindowProgress?
  let tag: ClassicSalmonRunRow.Tag?
  let terms: GameTerms
  let now: Date
  let metrics: CellMetrics

  var body: some View {
    Section {
      ClassicShiftCell(shift: shift, progress: progress, terms: terms, now: now, metrics: metrics)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(writer.sentence(for: shift, at: now))
    } header: {
      if tag != nil || shift.kind != .regular {
        header
          // The cell's sentence reads the kind and the times.
          .accessibilityHidden(true)
      }
    }
  }

  private var header: some View {
    HStack {
      if let tag {
        ClassicTag(text: tag.text)
      }
      if let label = shift.kind.label {
        ClassicKindTag(label: label, color: ModeColor(shift.kind))
      }

      Spacer()

      if tag == .soon {
        Text(verbatim: ClassicText.timeUntil.text(
          in: terms.language,
          timeFormat.span(.seconds(shift.startTime.timeIntervalSince(now)))))
          .countdownRoll(value: now)
          .scaledLimitedLine(for: metrics.arrangement)
          .ikaFont(.light, size: ClassicMetrics.Header.contentFontSize, relativeTo: .headline)
      }
    }
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - ClassicShiftCell

/// A Shift's cell: its kind's icon and time range, the Stage beside the four weapons, and the
/// progress bar with the time left while it runs.
struct ClassicShiftCell: View {
  typealias Scoped = ClassicMetrics.Shift

  @Environment(\.colorScheme) private var colorScheme
  @TimeSettings private var time

  let shift: Shift
  let progress: WindowProgress?
  let terms: GameTerms
  let now: Date
  let metrics: CellMetrics

  var body: some View {
    VStack(alignment: .leading, spacing: Scoped.cellSpacing) {
      timeSection

      switch metrics.arrangement {
        case .sideBySide:
          SalmonStageAndWeaponsLayout {
            stageCard
            ClassicWeaponsCard(weapons: shift.weapons, terms: terms, columnCount: 2)
          }

        case .stacked:
          stageCard
          ClassicWeaponsCard(weapons: shift.weapons, terms: terms, columnCount: 4)
      }

      if let progress {
        progressSection(progress)
          .transition(.opacity.animation(.default))
      }
    }
    // As ikalendar 2 (e33efad): a List pads a short cell on its own, so every cell is padded
    // alike to keep the rows evenly spaced.
    .padding(.vertical, Scoped.cellPaddingV)
  }

  // MARK: Time

  /// The kind's icon (on glass while it runs) and the time range in glass frames, where
  /// ikalendar 2 drew its golden egg or salmon.
  private var timeSection: some View {
    let isRunning: Bool = progress != nil
    let range: AnyLayout = metrics.arrangement == .stacked
      ? AnyLayout(VStackLayout(alignment: .trailing, spacing: Scoped.timeTextSpacing))
      : AnyLayout(HStackLayout(spacing: Scoped.timeTextSpacing))

    return HStack {
      kindIcon(isRunning: isRunning)
        .scaleEffect(isRunning ? Scoped.currentIconScale : Scoped.iconScale)
        .animation(.default, value: isRunning)

      Spacer()

      range {
        framedTime(timeFormat.shiftTime(shift.startTime, now: now))
        if metrics.arrangement == .sideBySide {
          timeText("-")
        }
        framedTime(timeFormat.shiftTime(shift.endTime, now: now))
      }
    }
  }

  /// The kind's icon, on a glass circle while the Shift runs.
  @ViewBuilder
  private func kindIcon(isRunning: Bool) -> some View {
    let icon = ClassicPicture(name: BundledImage.name(for: ModeIcon(shift.kind), size: .medium))
      .shadow(radius: ClassicMetrics.shadowRadius)
      .frame(height: metrics.length(.salmonIconHeight))

    if isRunning {
      icon.adaptiveGlassEffect(in: .circle)
    }
    else {
      icon
    }
  }

  private func framedTime(_ time: String) -> some View {
    timeText(time)
      .padding(.horizontal, Scoped.timeTextPaddingH)
      .padding(.vertical, Scoped.timeTextPaddingV)
      .adaptiveGlassEffect(in: .rect(cornerRadius: Scoped.timeTextCornerRadius))
  }

  private func timeText(_ text: String) -> some View {
    Text(verbatim: text)
      .scaledLimitedLine(for: metrics.arrangement)
      .ikaFont(.light, size: Scoped.timeTextFontSize, relativeTo: .headline)
  }

  // MARK: Stage

  private var stageCard: some View {
    ClassicShiftStageCard(
      stage: shift.stage,
      stageName: terms.name(of: shift.stage),
      kingSalmonid: shift.kingSalmonid,
      isRunning: progress != nil,
      arrangement: metrics.arrangement)
  }

  // MARK: Progress

  private func progressSection(_ progress: WindowProgress) -> some View {
    ProgressView(value: progress.sharePassed) {
      Text(verbatim: ClassicText.timeLeft.text(in: terms.language, timeFormat.span(progress.timeLeft)))
        .countdownRoll(value: now)
        .scaledLimitedLine(for: metrics.arrangement)
        .ikaFont(.light, size: Scoped.progressFontSize, relativeTo: .headline)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .tint(ModeColor(shift.kind).classicTint(in: colorScheme))
  }

  private var timeFormat: ClassicTimeFormat { time.classicFormat(terms.language) }
}

// MARK: - ClassicShiftStageCard

/// A Shift's Stage picture with its name on a glass label and its King Salmonid on glass in the
/// corner where ikalendar 2 showed the reward gear: name first while the Shift runs, King
/// Salmonid first otherwise, as ikalendar 2 swapped them. When the cell stacks, the name sits
/// under the picture, where it can wrap.
struct ClassicShiftStageCard: View {
  typealias Scoped = ClassicMetrics.Shift

  @State private var cardWidth: CGFloat = 0

  let stage: StageID
  let stageName: String
  let kingSalmonid: KingSalmonidID?
  let isRunning: Bool
  let arrangement: CellArrangement

  var body: some View {
    switch arrangement {
      case .sideBySide:
        picture
          .overlay(alignment: .bottom) {
            HStack(alignment: .bottom) {
              if isRunning {
                label
                Spacer()
                king
              }
              else {
                king
                Spacer()
                label
              }
            }
            .padding(Scoped.overlayPadding)
          }

      case .stacked:
        VStack(alignment: .trailing, spacing: ClassicMetrics.BattleSecondary.stageSpacingV) {
          picture
            .overlay(alignment: .bottomLeading) {
              king
                .padding(Scoped.overlayPadding)
            }
          Text(verbatim: stageName)
            .scaledLimitedLine(for: arrangement)
            .multilineTextAlignment(.trailing)
            .ikaFont(.light, size: Scoped.stageLabelFontSize, relativeTo: .body)
        }
    }
  }

  private var picture: some View {
    ClassicPicture(name: BundledImage.name(for: stage, size: .large))
      .clipShape(.rect(cornerRadius: Scoped.stageCornerRadius))
      .adaptiveGlassEffect(in: .rect(cornerRadius: Scoped.stageCornerRadius))
      .shadow(radius: ClassicMetrics.shadowRadius)
      .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { cardWidth = $0 }
  }

  private var label: some View {
    ClassicStageLabel(name: stageName, fontSize: Scoped.stageLabelFontSize, arrangement: arrangement)
  }

  @ViewBuilder private var king: some View {
    if let kingSalmonid {
      ClassicPicture(name: BundledImage.name(for: kingSalmonid, size: .medium))
        .padding(Scoped.kingSalmonidPadding)
        .frame(width: cardWidth * Scoped.kingSalmonidWidthRatio)
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: Scoped.kingSalmonidCornerRadius))
    }
  }
}

// MARK: - ClassicWeaponsCard

/// A Shift's four weapons on glass, in a two by two grid beside the Stage, or in one row under it
/// when the cell stacks, where the pictures need not grow with the text. The random marks show
/// the game's green and golden question marks. Each picture is labelled with the weapon's name.
struct ClassicWeaponsCard: View {
  let weapons: [WeaponID]
  let terms: GameTerms
  let columnCount: Int

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columnCount)) {
      // By position: a Shift can list one weapon more than once, such as four random marks.
      ForEach(Array(weapons.enumerated()), id: \.offset) { _, weapon in
        Image(BundledImage.name(for: weapon, size: .large), bundle: BundledImage.catalogBundle)
          .antialiased(true)
          .resizable()
          .scaledToFit()
          .shadow(radius: ClassicMetrics.shadowRadius)
          .padding(ClassicMetrics.Shift.weaponPadding)
          .adaptiveGlassEffect(in: .rect(cornerRadius: ClassicMetrics.Shift.weaponCornerRadius))
          .accessibilityLabel(Text(verbatim: terms.name(of: weapon)))
      }
    }
  }
}
#endif
