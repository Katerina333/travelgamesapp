import SwiftUI

/// Primary CTA button — large, rounded, springy, themed (§5.2).
public struct PrimaryButton: View {
    let titleKey: LocalizedStringKey
    let tokens: ThemeTokens
    let icon: String?
    let action: () -> Void

    public init(_ titleKey: LocalizedStringKey, tokens: ThemeTokens, icon: String? = nil, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.tokens = tokens
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                if let icon { Image(systemName: icon) }
                Text(titleKey)
            }
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                LinearGradient(
                    colors: [tokens.accentPrimary, tokens.accentPrimary.opacity(0.82)],
                    startPoint: .top, endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: Radius.l)
            )
            .shadow(color: tokens.accentPrimary.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

/// Secondary / ghost button.
public struct GhostButton: View {
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
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(tokens.contentSecondary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(tokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: Radius.m))
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

/// Traveler avatar chip with name — used in setup and leaderboards (§5.2).
public struct PlayerChip: View {
    let name: String
    let symbol: String
    let colorIndex: Int
    let tokens: ThemeTokens

    public init(name: String, symbol: String, colorIndex: Int, tokens: ThemeTokens) {
        self.name = name
        self.symbol = symbol
        self.colorIndex = colorIndex
        self.tokens = tokens
    }

    public var body: some View {
        HStack(spacing: Spacing.s) {
            AvatarView(symbol: symbol, colorIndex: colorIndex, size: 30)
            Text(verbatim: name)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(tokens.contentPrimary)
        }
        .padding(.leading, Spacing.xs)
        .padding(.trailing, Spacing.m)
        .padding(.vertical, Spacing.xs)
        .background(tokens.surfaceCard, in: Capsule())
    }
}

/// Large, colorful game card for the trip board (§5.2).
public struct GameCard: View {
    let titleKey: LocalizedStringKey
    let icon: String
    let colorIndex: Int
    let inProgress: Bool
    let tokens: ThemeTokens

    public init(titleKey: LocalizedStringKey, icon: String, colorIndex: Int, inProgress: Bool, tokens: ThemeTokens) {
        self.titleKey = titleKey
        self.icon = icon
        self.colorIndex = colorIndex
        self.inProgress = inProgress
        self.tokens = tokens
    }

    private var color: Color { AvatarCatalog.color(colorIndex) }

    public var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.m)
                    .fill(color.opacity(0.18))
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(tokens.contentPrimary)
                if inProgress {
                    Text("trip.status.inProgress")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(tokens.accentWarning)
                }
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(color)
        }
        .padding(Spacing.m)
        .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.l))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(color.opacity(0.20), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
