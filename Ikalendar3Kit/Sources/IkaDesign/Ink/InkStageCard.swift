//
//  InkStageCard.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import WidgetKit

// MARK: - InkStageCard

/// A Stage's bundled picture, as wide as it is offered, with the Stage's name on a black tag that
/// straddles the picture's bottom edge. The picture is decorative: VoiceOver reads the name. In
/// the plain form the picture is desaturated in accented rendering and the name sits below it,
/// since a tag with no fill cannot sit on a picture.
public struct InkStageCard: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  private let stage: StageID
  private let name: Text
  private let imageSize: BundledImage.Size
  private let nameReachesTrailingEdge: Bool

  /// The card of `stage`, labelled `name`, drawn from its bundled picture at `imageSize`. The
  /// name tag keeps the same inset from both of the picture's sides, or with
  /// `nameReachesTrailingEdge` only from the leading one, where a long name needs the card's
  /// whole width, as on a small card.
  public init(stage: StageID, name: Text, imageSize: BundledImage.Size, nameReachesTrailingEdge: Bool = false) {
    self.stage = stage
    self.name = name
    self.imageSize = imageSize
    self.nameReachesTrailingEdge = nameReachesTrailingEdge
  }

  public var body: some View {
    let straddlesEdge: Bool = renderingMode.drawsInkMaterials

    ZStack(alignment: Alignment(horizontal: .leading, vertical: .stagePictureBottom)) {
      picture
      InkTagLabel(text: name, style: .caption, colors: InkPair.tagText.colors(in: colorScheme))
        .padding(.leading, InkMetrics.stageNameInset)
        .padding(.trailing, nameReachesTrailingEdge ? 0 : InkMetrics.stageNameInset)
        .alignmentGuide(.stagePictureBottom) { dimensions in
          straddlesEdge
            ? dimensions[VerticalAlignment.center]
            : dimensions[.top] - InkMetrics.plainStageNameSpacing
        }
    }
  }

  private var picture: some View {
    Color.clear
      .aspectRatio(InkMetrics.pictureAspectRatio, contentMode: .fit)
      .overlay {
        Image(decorative: BundledImage.name(for: stage, size: imageSize), bundle: BundledImage.catalogBundle)
          .resizable()
          .widgetAccentedRenderingMode(.desaturated)
          .scaledToFill()
      }
      .clipShape(.rect(cornerRadius: InkMetrics.pictureCornerRadius))
  }
}

// MARK: - VerticalAlignment

extension VerticalAlignment {
  /// A Stage picture's bottom edge, which the name tag straddles.
  private enum StagePictureBottom: AlignmentID {
    static func defaultValue(in dimensions: ViewDimensions) -> CGFloat {
      dimensions[.bottom]
    }
  }

  static fileprivate let stagePictureBottom: VerticalAlignment = .init(StagePictureBottom.self)
}

// MARK: - Previews

#Preview("Stage cards") {
  InkPreviewGallery {
    HStack(alignment: .top) {
      // Scorch Gorge, and an id no build bundles, which shows the placeholder.
      InkStageCard(stage: StageID("VnNTdGFnZS0x"), name: Text(verbatim: "Scorch Gorge"), imageSize: .medium)
      InkStageCard(stage: StageID("VnNTdGFnZS05OTk="), name: Text(verbatim: "New Stage"), imageSize: .medium)
    }
  }
}
