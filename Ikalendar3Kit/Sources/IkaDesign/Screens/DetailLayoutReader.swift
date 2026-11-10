//
//  DetailLayoutReader.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - DetailLayoutReader

/// Reads the width a Mode's detail is offered and its text size, and gives its content the
/// `DetailLayout` they call for, as its place chooses (`detailLayout(_:)`). The shared Battle Mode
/// and Salmon Run screens wrap their Style's view in it, so a detail switches between the iPhone
/// list and the wide detail as its window or column resizes, unless its place chose the list.
public struct DetailLayoutReader<Content: View>: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.detailLayoutChoice) private var choice

  private let content: (DetailLayout) -> Content

  public init(@ViewBuilder content: @escaping (DetailLayout) -> Content) {
    self.content = content
  }

  public var body: some View {
    GeometryReader { proxy in
      content(DetailLayout(choice, width: proxy.size.width, dynamicTypeSize: dynamicTypeSize))
    }
  }
}

// MARK: - Choice

extension View {
  /// Has every screen inside show the detail layout `choice` gives: `.list` where screens stay as
  /// on iPhone by design, whatever width they get.
  public func detailLayout(_ choice: DetailLayoutChoice) -> some View {
    environment(\.detailLayoutChoice, choice)
  }
}

extension EnvironmentValues {
  /// The detail layout choice of the place a screen sits in; by width unless the place chose.
  @Entry var detailLayoutChoice: DetailLayoutChoice = .byWidth
}
