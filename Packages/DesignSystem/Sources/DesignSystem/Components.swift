import SwiftUI

/// Primary CTA button — large tap target, rounded, themed (§5.2).
public struct PrimaryButton: View {
    let titleKey: LocalizedStringKey
    let tokens: ThemeTokens
    let action: () -> Void

    public init(_ titleKey: LocalizedStringKey, tokens: ThemeTokens, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.tokens = tokens
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: TapTarget.minimum)
        }
        .buttonStyle(.borderedProminent)
        .tint(tokens.accentPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.m))
    }
}

/// Traveler avatar chip with name — used in setup and leaderboards (§5.2).
public struct PlayerChip: View {
    let name: String
    let symbol: String
    let tokens: ThemeTokens

    public init(name: String, symbol: String, tokens: ThemeTokens) {
        self.name = name
        self.symbol = symbol
        self.tokens = tokens
    }

    public var body: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: symbol)
                .foregroundStyle(tokens.accentPrimary)
            Text(name)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(tokens.contentPrimary)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(tokens.surfaceCard, in: Capsule())
    }
}
