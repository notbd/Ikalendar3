//
//  Image+StoredFile.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import SwiftUI

extension Image {
  /// A stored image file, such as the Splatfest art the refresh engine keeps, or `nil` when it
  /// does not decode.
  init?(contentsOf file: URL) {
    #if os(iOS)
    guard let image = UIImage(contentsOfFile: file.path(percentEncoded: false)) else { return nil }

    self.init(uiImage: image)
    #else
    guard let image = NSImage(contentsOf: file) else { return nil }

    self.init(nsImage: image)
    #endif
  }
}
#endif
