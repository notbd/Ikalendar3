//
//  AboutView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import StoreKit
import SwiftUI

// MARK: - AboutView

/// The About page Settings opens, in the system's grouped form, as ikalendar 2's: the icon (which
/// bounces when tapped), name and version; Share; Rate, Leave a Review and View on the App Store;
/// Contact; the website, the source code and its licence, and the privacy policy; Debug Options;
/// and a footer pointing back to ikalendar2.
///
/// Every link opens in the browser, Mail or the App Store. The rows that need ikalendar 3's App
/// Store id stay disabled until it exists (`AppStoreApp.ikalendar3`).
struct AboutView: View {
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language
  @Environment(\.openURL) private var openURL
  @Environment(\.requestReview) private var requestReview

  /// Counts the icon's taps; each one bounces it.
  @State private var iconBounces = 0
  /// Counts the Rate row's taps; each one wiggles its symbol.
  @State private var rateTaps = 0
  @State private var isAppStoreOverlayPresented = false

  @ScaledMetric(relativeTo: .title) private var littleBuddyHeight: CGFloat = 36

  var body: some View {
    Form {
      Section {
        header
      }
      .listRowBackground(Color.clear)

      Section(text(.share)) {
        shareRow
      }

      Section(text(.review)) {
        rateRow
        leaveReviewRow
        viewOnAppStoreRow
      }

      Section(text(.contact)) {
        twitterRow
        emailRow
      }

      Section(text(.app)) {
        linkRow(text(.website), systemImage: "globe", url: AboutLink.website)
        NavigationLink {
          LicenseView(license: .ikalendar3)
        } label: {
          AboutRowLabel(text(.sourceCode), systemImage: "chevron.left.slash.chevron.right")
        }
        linkRow(text(.privacyPolicy), systemImage: "hand.raised", url: AboutLink.privacyPolicy)
      }

      Section {
        NavigationLink {
          DebugOptionsView()
        } label: {
          AboutRowLabel(text(.debugOptions), systemImage: "hammer")
        }
      } footer: {
        ikalendar2Footer
      }
    }
    .formStyle(.grouped)
    .navigationTitle(SettingsText.about.text(in: language))
  }

  // MARK: Header

  /// The icon, name and version. The top padding leaves room for the bounce's hop inside the row,
  /// which clips its content.
  private var header: some View {
    VStack {
      AppIconMark(size: 120)
        .onTapGesture { iconBounces += 1 }
        .squashBounce(trigger: iconBounces, amplitude: .aboutIcon)
        .sensoryFeedback(Haptic.iconBounce, trigger: iconBounces)
        .zIndex(1)

      Text(verbatim: Ikalendar3App.name)
        .font(.system(.title, design: .rounded, weight: .bold))
        .foregroundStyle(Color.accentColor)

      Text(text(.version, Self.version, Self.build))
        .font(.system(.subheadline, design: .monospaced))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 36)
  }

  // MARK: Rows

  @ViewBuilder
  private var shareRow: some View {
    if let app = AppStoreApp.ikalendar3 {
      ShareLink(item: app.page) { shareLabel }
    }
    else {
      Button { } label: { shareLabel }
        .disabled(true)
    }
  }

  private var shareLabel: some View {
    AboutRowLabel(text(.shareApp, Ikalendar3App.name), systemImage: "square.and.arrow.up")
  }

  /// Asks the system for its rating prompt. The symbol nudges until the first tap.
  private var rateRow: some View {
    Button {
      requestReview()
      rateTaps += 1
      preferences.hasDiscoveredRating = true
    } label: {
      AboutRowLabel(text(.rate, Ikalendar3App.name)) {
        Image(systemName: "star.bubble.fill")
          .symbolEffect(.wiggle, value: rateTaps)
          .iconNudge(isActive: !preferences.hasDiscoveredRating)
      }
    }
    .sensoryFeedback(.selection, trigger: rateTaps)
  }

  private var leaveReviewRow: some View {
    Button {
      guard let app = AppStoreApp.ikalendar3 else { return }

      openURL(app.writeReview)
    } label: {
      AboutRowLabel(text(.leaveReview), systemImage: "highlighter")
    }
    .disabled(AppStoreApp.ikalendar3 == nil)
  }

  /// The App Store's overlay on iPhone and iPad; the App Store app on the Mac.
  private var viewOnAppStoreRow: some View {
    Button {
      guard let app = AppStoreApp.ikalendar3 else { return }

      #if os(iOS)
      isAppStoreOverlayPresented = true
      #else
      openURL(app.page)
      #endif
    } label: {
      AboutRowLabel(text(.viewOnAppStore, Ikalendar3App.name), systemImage: "doc.viewfinder.fill")
    }
    .disabled(AppStoreApp.ikalendar3 == nil)
    #if os(iOS)
    .appStoreOverlay(isPresented: $isAppStoreOverlayPresented) {
      SKOverlay.AppConfiguration(appIdentifier: AppStoreApp.ikalendar3?.id ?? "", position: .bottom)
    }
    #endif
  }

  private var twitterRow: some View {
    Button {
      openURL(AboutLink.twitter)
    } label: {
      LabeledContent {
        Text(verbatim: AboutLink.twitterHandle)
      } label: {
        AboutRowLabel("Twitter", systemImage: "at")
      }
    }
  }

  private var emailRow: some View {
    Button {
      openURL(AboutLink.email)
    } label: {
      LabeledContent {
        Text(verbatim: AppContact.email)
      } label: {
        AboutRowLabel(text(.email), systemImage: "envelope")
      }
    }
  }

  private func linkRow(_ title: String, systemImage: String, url: URL) -> some View {
    Button {
      openURL(url)
    } label: {
      AboutRowLabel(title, systemImage: systemImage)
    }
  }

  // MARK: Footer

  /// The little buddy and the two-line note, which opens ikalendar 2's App Store page.
  private var ikalendar2Footer: some View {
    Button {
      openURL(AppStoreApp.ikalendar2.page)
    } label: {
      HStack {
        Image(.littleBuddy)
          .resizable()
          .scaledToFit()
          .saturation(0.6)
          .frame(height: littleBuddyHeight)
          .padding(.vertical)
          .padding(.trailing, 10)
          .accessibilityHidden(true)

        Text(text(.ikalendar2Note))
          .ikaFont(.light, size: 13, relativeTo: .footnote)
          // The face's own line gap spaces its lines twice as far apart as the system font's.
          .lineHeight(.multiple(factor: 1.25))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
          .minimumScaleFactor(0.5)
      }
    }
    .buttonStyle(.plain)
  }

  // MARK: Helpers

  private func text(_ text: AboutText, _ arguments: any CVarArg...) -> String {
    text.text(in: language, arguments: arguments)
  }

  /// The marketing version, such as `1.0.0`.
  static private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
  /// The build number.
  static private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
}

// MARK: - AboutRowLabel

/// A row's symbol and title, as ikalendar 2's rows: the symbol in the tint, the title primary
/// even on a button, which would tint it, and secondary while the row is disabled.
private struct AboutRowLabel<Icon: View>: View {
  @Environment(\.isEnabled) private var isEnabled

  let title: String
  @ViewBuilder let icon: Icon

  init(_ title: String, @ViewBuilder icon: () -> Icon) {
    self.title = title
    self.icon = icon()
  }

  var body: some View {
    Label {
      Text(title)
        .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
    } icon: {
      icon
    }
  }
}

extension AboutRowLabel where Icon == Image {
  init(_ title: String, systemImage: String) {
    self.init(title) { Image(systemName: systemImage) }
  }
}
