//
//  IkaIntentsPackage.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents

/// This module's App Intents types. A target that uses them lists this package in its own
/// `AppIntentsPackage`, so the build adds them to the target's App Intents metadata and the
/// system finds them, such as the Battle Mode a widget is set to or the Mode a watch complication
/// is set to.
///
/// On watchOS the module holds only the parameter types: everything else in it is behind
/// `#if os(iOS)` (Live Activities and the background task) or `#if !os(watchOS)` (the effects
/// shell), and App Shortcuts must be too.
public struct IkaIntentsPackage: AppIntentsPackage { }
