//
//  DetailLayoutReader.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - DetailLayoutReader

/// Reads the width a Mode's detail is offered and its text size, and gives its content the
/// `DetailLayout` they call for. The shared Battle Mode and Salmon Run screens wrap their Style's
/// view in it, so a detail switches between the iPhone list and the wide detail as its window
/// or column resizes.
public struct DetailLayoutReader<Content: View>: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private let content: (DetailLayout) -> Content

  public init(@ViewBuilder content: @escaping (DetailLayout) -> Content) {
    self.content = content
  }

  public var body: some View {
    GeometryReader { proxy in
      content(DetailLayout(width: proxy.size.width, dynamicTypeSize: dynamicTypeSize))
    }
  }
}
