//
//  AppGroup.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - AppGroup

/// The App Group the app and its widget extension share on iPhone, iPad and Mac. Its container
/// holds the feed cache and the preferences that every process on the device reads. The watch
/// has no App Group: it keeps its own container.
public enum AppGroup {
  /// The group's identifier, derived from the bundle identifier `io.tianwei.ikalendar3`. Every
  /// target's entitlements list the same value.
  static public let identifier = "group.io.tianwei.ikalendar3"
}
