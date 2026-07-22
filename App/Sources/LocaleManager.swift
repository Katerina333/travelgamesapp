import Foundation
import Observation

/// In-app language override (§4.4). Persists the choice, drives both SwiftUI
/// string resolution (via `\.locale` + a root `.id`) and ContentKit pack
/// loading (via the `AppleLanguages` default). "System" follows the device.
@Observable
final class LocaleManager {
    static let systemTag = "system"
    private static let storageKey = "appLanguageTag"
    private static let appleLanguagesKey = "AppleLanguages"

    /// Launch locales (§4.4) shown in their own language (autonyms).
    static let languages: [(tag: String, name: String)] = [
        (systemTag, ""), // display name comes from a localized string
        ("en-US", "English (US)"),
        ("en-GB", "English (UK)"),
        ("en-AU", "English (Australia)"),
        ("es-MX", "Español (México)"),
        ("pt-BR", "Português (Brasil)"),
        ("uk", "Українська"),
        ("fr-FR", "Français"),
        ("fr-CA", "Français (Canada)"),
        ("zh-Hans", "简体中文")
    ]

    var tag: String {
        didSet { apply() }
    }

    init() {
        // UI tests launch with a clean, system language for isolation.
        if CommandLine.arguments.contains("-uitest-reset") {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
            UserDefaults.standard.removeObject(forKey: Self.appleLanguagesKey)
            tag = Self.systemTag
            return
        }
        tag = UserDefaults.standard.string(forKey: Self.storageKey) ?? Self.systemTag
        apply() // ensure AppleLanguages matches the persisted choice at launch
    }

    /// Locale to inject into the SwiftUI environment.
    var locale: Locale {
        tag == Self.systemTag ? .autoupdatingCurrent : Locale(identifier: tag)
    }

    /// Applies the choice: persists it and sets `AppleLanguages` so content
    /// packs (which read that key) switch immediately, and so a relaunch keeps
    /// the language. Call once at launch too.
    func apply() {
        let defaults = UserDefaults.standard
        if tag == Self.systemTag {
            defaults.removeObject(forKey: Self.storageKey)
            defaults.removeObject(forKey: Self.appleLanguagesKey)
        } else {
            defaults.set(tag, forKey: Self.storageKey)
            defaults.set([tag], forKey: Self.appleLanguagesKey)
        }
    }
}
