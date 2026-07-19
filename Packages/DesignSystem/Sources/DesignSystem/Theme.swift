import SwiftUI

/// Theme selection (§5.1): Light, Night (in-car dark, near-black, low
/// saturation), and Auto (follows system appearance).
public enum ThemeMode: String, CaseIterable, Codable, Sendable {
    case auto
    case light
    case night

    /// Resolves to concrete tokens given the system appearance.
    public func resolvedTokens(systemDark: Bool) -> ThemeTokens {
        switch self {
        case .light: return .light
        case .night: return .night
        case .auto: return systemDark ? .night : .light
        }
    }
}

/// Semantic color tokens — components never use raw colors (§5.1).
public struct ThemeTokens: Sendable {
    public let backgroundPrimary: Color
    public let backgroundSecondary: Color
    public let surfaceCard: Color
    public let contentPrimary: Color
    public let contentSecondary: Color
    public let accentPrimary: Color
    public let accentSuccess: Color
    public let accentWarning: Color
    public let gameCategoryColors: [Color]

    public static let light = ThemeTokens(
        backgroundPrimary: Color(red: 0.98, green: 0.97, blue: 0.95),
        backgroundSecondary: Color(red: 0.94, green: 0.93, blue: 0.90),
        surfaceCard: .white,
        contentPrimary: Color(red: 0.12, green: 0.13, blue: 0.18),
        contentSecondary: Color(red: 0.42, green: 0.43, blue: 0.48),
        accentPrimary: Color(red: 0.98, green: 0.45, blue: 0.16),
        accentSuccess: Color(red: 0.20, green: 0.66, blue: 0.39),
        accentWarning: Color(red: 0.95, green: 0.68, blue: 0.15),
        gameCategoryColors: [
            Color(red: 0.98, green: 0.45, blue: 0.16),
            Color(red: 0.24, green: 0.55, blue: 0.90),
            Color(red: 0.55, green: 0.36, blue: 0.86),
            Color(red: 0.20, green: 0.66, blue: 0.39)
        ]
    )

    /// Night: near-black backgrounds (#0D0F14 range), reduced saturation —
    /// avoids lighting up the cabin (§5.1).
    public static let night = ThemeTokens(
        backgroundPrimary: Color(red: 0.051, green: 0.059, blue: 0.078),
        backgroundSecondary: Color(red: 0.08, green: 0.09, blue: 0.12),
        surfaceCard: Color(red: 0.11, green: 0.12, blue: 0.16),
        contentPrimary: Color(red: 0.90, green: 0.90, blue: 0.92),
        contentSecondary: Color(red: 0.60, green: 0.61, blue: 0.66),
        accentPrimary: Color(red: 0.85, green: 0.48, blue: 0.25),
        accentSuccess: Color(red: 0.30, green: 0.60, blue: 0.42),
        accentWarning: Color(red: 0.80, green: 0.62, blue: 0.28),
        gameCategoryColors: [
            Color(red: 0.85, green: 0.48, blue: 0.25),
            Color(red: 0.35, green: 0.52, blue: 0.75),
            Color(red: 0.52, green: 0.42, blue: 0.72),
            Color(red: 0.30, green: 0.60, blue: 0.42)
        ]
    )
}

/// App-wide theme state, injected via SwiftUI environment.
@Observable
public final class ThemeManager {
    public var mode: ThemeMode

    public init(mode: ThemeMode = .auto) {
        self.mode = mode
    }

    public func tokens(systemDark: Bool) -> ThemeTokens {
        mode.resolvedTokens(systemDark: systemDark)
    }
}
