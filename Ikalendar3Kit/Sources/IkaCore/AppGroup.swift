//
//  AppGroup.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - AppGroup

/// The App Group the app and its widget extension share on iPhone, iPad and Mac, and the watch
/// app and its widget extension share on the watch: one container per device. It holds the feed
/// cache and the preferences that every process on that device reads.
public enum AppGroup {
  /// The group's identifier, derived from the bundle identifier `io.tianwei.ikalendar3`. Every
  /// target's entitlements list the same value.
  static public let identifier = "group.io.tianwei.ikalendar3"
}
