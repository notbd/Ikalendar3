//
//  SettingsView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - SettingsView

/// Settings, in the system's grouped form in every Style, as ikalendar 2's: Default Mode (iPhone
/// only), Appearance, Style, Language, Reminders, then About and Credits.
///
/// Every control writes straight to the preferences store, which persists the value and which
/// every screen observes, so a new Style or colour scheme applies at once. iPhone and iPad present
/// it from the tabs (`settingsPresentation(isPresented:)`); the Mac shows it in its standard
/// Settings window, opened with Command-comma, without the iPhone-only rows.
struct SettingsView: View {
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language
  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        if isPhone { defaultModeSection }
        appearanceSection
        styleSection
        languageSection
        remindersSection
        aboutSection
      }
      .formStyle(.grouped)
      .navigationTitle(text(.title))
      #if os(iOS)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .close) { dismiss() }
        }
      }
      #endif
    }
    #if os(macOS)
    // The Settings window can stay open after every schedule window closes, so it applies the
    // scheme itself.
    .appColorScheme(preferences.colorScheme)
    .frame(width: 500)
    .frame(minHeight: 520, idealHeight: 680)
    #endif
  }

  // MARK: Sections

  private var defaultModeSection: some View {
    @Bindable var preferences = preferences
    return Section(text(.defaultMode)) {
      Picker(selection: $preferences.defaultMode) {
        ForEach(ModeTab.allCases, id: \.self) { tab in
          Text(tab.label.text(in: language)).tag(tab)
        }
      } label: {
        Label(text(.defaultTab), systemImage: preferences.defaultMode.systemImage)
          .contentTransition(.symbolEffect(.replace))
      }
    }
  }

  private var appearanceSection: some View {
    @Bindable var preferences = preferences
    return Section(text(.appearance)) {
      Picker(selection: $preferences.colorScheme) {
        ForEach(ColorSchemePreference.allCases, id: \.self) { scheme in
          Label(text(scheme.name), systemImage: scheme.systemImage).tag(scheme)
        }
      } label: {
        Label(text(.colorScheme), systemImage: "circle.lefthalf.filled")
      }

      if isPhone {
        Toggle(isOn: $preferences.shouldMinimizeTabBar) {
          Label(
            text(.minimizeTabBar),
            systemImage: preferences.shouldMinimizeTabBar
              ? "arrow.right.and.line.vertical.and.arrow.left"
              : "arrow.left.and.line.vertical.and.arrow.right")
            .contentTransition(.symbolEffect(.replace))
        }
      }
    }
  }

  private var styleSection: some View {
    @Bindable var preferences = preferences
    return Section(text(.style)) {
      Picker(text(.style), selection: $preferences.style) {
        ForEach(Style.allCases, id: \.self) { style in
          Text(text(style.name)).tag(style)
        }
      }
      .pickerStyle(.inline)
      .labelsHidden()
    }
  }

  /// Shows the app language and opens where the system changes it: the app's page in the
  /// Settings app, or the Mac's Language & Region pane, which sets each app's language.
  private var languageSection: some View {
    Section(text(.language)) {
      Button {
        guard let url = Self.languageSettingsURL else { return }

        openURL(url)
      } label: {
        LabeledContent {
          HStack {
            Text(language.nativeName)
            Image(systemName: "arrow.up.forward.app.fill")
          }
          .foregroundStyle(.secondary)
        } label: {
          Label {
            // A button tints its label; the title stays primary, as in ikalendar 2.
            Text(text(.appLanguage))
              .foregroundStyle(Color.primary)
          } icon: {
            Image(systemName: language.globeSymbol)
          }
        }
      }
    }
  }

  /// The four switches. Scheduling the reminders and asking for permission come with reminders
  /// themselves; Settings only stores the switches.
  private var remindersSection: some View {
    @Bindable var preferences = preferences
    return Section(text(.reminders)) {
      Toggle(ModeLabel.bigRun.text(in: language), isOn: $preferences.isBigRunReminderOn)
      Toggle(ModeLabel.eggstraWork.text(in: language), isOn: $preferences.isEggstraWorkReminderOn)
      Toggle(ModeLabel.splatfest.text(in: language), isOn: $preferences.isSplatfestReminderOn)
      Toggle(ModeLabel.challenges.text(in: language), isOn: $preferences.isChallengeReminderOn)
    }
  }

  private var aboutSection: some View {
    Section {
      NavigationLink {
        AboutView()
      } label: {
        Label(text(.about), systemImage: "house.fill")
      }

      NavigationLink {
        CreditsView()
      } label: {
        Label(text(.credits), systemImage: "bookmark.fill")
      }
    }
  }

  // MARK: Helpers

  private func text(_ text: SettingsText) -> String {
    text.text(in: language)
  }
}

// MARK: - Platform

extension SettingsView {
  /// Whether the iPhone-only rows show: Default Mode and Minimize Tab Bar, which only the
  /// iPhone's tab bar uses.
  private var isPhone: Bool {
    #if os(iOS)
    UIDevice.current.userInterfaceIdiom == .phone
    #else
    false
    #endif
  }

  /// Where the system changes the app language, or `nil` if the system has no such page.
  static private var languageSettingsURL: URL? {
    #if os(iOS)
    URL(string: UIApplication.openSettingsURLString)
    #else
    URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension")
    #endif
  }
}

// MARK: - Presentation

extension View {
  /// The toolbar button that shows Settings on iPhone and iPad, as in ikalendar 2. The Mac opens
  /// its Settings window from the app menu or with Command-comma instead, so it has none.
  func settingsButton(isPresented: Binding<Bool>, language: GameLanguage) -> some View {
    #if os(iOS)
    toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(SettingsText.title.text(in: language), systemImage: "gear") {
          isPresented.wrappedValue = true
        }
      }
    }
    #else
    self
    #endif
  }

  /// Presents Settings on iPhone and iPad as ikalendar 2 does: full screen on iPhone, a page
  /// sheet on iPad, closed only with its close button, with a rigid impact each time it shows.
  /// The Mac shows Settings in its own window instead.
  func settingsPresentation(isPresented: Binding<Bool>) -> some View {
    #if os(iOS)
    Group {
      if UIDevice.current.userInterfaceIdiom == .phone {
        fullScreenCover(isPresented: isPresented) { SettingsView() }
      }
      else {
        sheet(isPresented: isPresented) {
          SettingsView()
            .presentationSizing(.page)
            .interactiveDismissDisabled()
        }
      }
    }
    .sensoryFeedback(trigger: isPresented.wrappedValue) { _, isShown in
      Haptic.settingsPresentationChanged(to: isShown)
    }
    #else
    self
    #endif
  }
}

// MARK: - Option names

extension ColorSchemePreference {
  /// The option's name in the colour scheme picker.
  fileprivate var name: SettingsText {
    switch self {
      case .followSystem: .followSystem
      case .dark: .dark
      case .light: .light
    }
  }

  /// The option's symbol, as in ikalendar 2.
  fileprivate var systemImage: String {
    switch self {
      case .followSystem: "macbook.and.iphone"
      case .dark: "moon.fill"
      case .light: "sun.max.fill"
    }
  }
}

extension Style {
  /// The Style's name in the Style picker.
  fileprivate var name: SettingsText {
    switch self {
      case .classic: .classic
      case .ink: .ink
      case .timeline: .timeline
    }
  }
}

extension GameLanguage {
  /// The globe turned to where the text set is spoken, as ikalendar 2's language row shows it.
  fileprivate var globeSymbol: String {
    switch self {
      case .enUS,
           .esMX,
           .frCA: "globe.americas.fill"
      case .enGB,
           .esES,
           .frFR,
           .deDE,
           .itIT,
           .nlNL,
           .ruRU: "globe.europe.africa.fill"
      case .jaJP,
           .koKR,
           .zhCN,
           .zhTW: "globe.asia.australia.fill"
    }
  }
}
