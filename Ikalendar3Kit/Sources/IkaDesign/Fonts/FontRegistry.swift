//
//  FontRegistry.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreText
import Foundation
import OSLog
import Synchronization

// MARK: - FontRegistry

/// Registers SplatNet 3's faces with Core Text for this process and remembers which ones it has.
///
/// Each target calls `register(from:)` once at start (ticket 16). Any number of faces may be
/// present, none included (CI and fresh clones have no font files): text set in a missing face
/// falls back along its `FontCascade`.
public enum FontRegistry {
  static private let faces: Mutex<Set<FontFace>> = .init([])

  /// The faces this process has registered so far.
  static public var registered: Set<FontFace> {
    faces.withLock { $0 }
  }

  /// Registers every face found in `folder` as `<name>.otf` or `<name>.ttf` and logs which ones.
  /// A missing folder counts as an empty one.
  ///
  /// - Returns: The faces registered from `folder`.
  @discardableResult
  static public func register(from folder: URL) -> Set<FontFace> {
    let registeredNow: Set<FontFace> = Set(FontFace.allCases.filter { register($0, in: folder) })
    faces.withLock { $0.formUnion(registeredNow) }

    if registeredNow.isEmpty {
      Logger.fonts.notice(
        "No font face registered from \(folder.path, privacy: .public); text uses the system font")
    }
    else {
      let names: String = FontFace.allCases.filter(registeredNow.contains).map(\.name).joined(separator: ", ")
      Logger.fonts.notice(
        """
        Registered \(registeredNow.count) of \(FontFace.allCases.count) font faces \
        from \(folder.path, privacy: .public): \(names, privacy: .public)
        """)
    }
    return registeredNow
  }

  /// Registers `face` from its file in `folder`, if there is one and it holds exactly that face.
  static private func register(_ face: FontFace, in folder: URL) -> Bool {
    let candidates: [URL] = ["otf", "ttf"].map { folder.appending(path: "\(face.name).\($0)") }
    guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
      return false
    }

    let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] ?? []
    let postScriptNames: [String] = descriptors.compactMap {
      CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String
    }
    guard postScriptNames == [face.name] else {
      Logger.fonts.error(
        """
        \(url.lastPathComponent, privacy: .public) is not the face \(face.name, privacy: .public): \
        it holds [\(postScriptNames.joined(separator: ", "), privacy: .public)]
        """)
      return false
    }

    var error: Unmanaged<CFError>?
    guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) else {
      let cfError: CFError? = error?.takeRetainedValue()
      if let cfError, CFErrorGetCode(cfError) == CTFontManagerError.alreadyRegistered.rawValue {
        return true
      }
      let reason: String = cfError.map { String(describing: $0) } ?? "unknown error"
      Logger.fonts.error("\(url.lastPathComponent, privacy: .public) failed to register: \(reason, privacy: .public)")
      return false
    }

    return true
  }
}
