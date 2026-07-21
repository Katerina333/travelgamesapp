import SwiftUI

/// Kid-friendly avatar catalog — a symbol + a background color per traveler,
/// so players are recognisable at a glance across the app (§5.3).
public enum AvatarCatalog {
    /// SF Symbols that read as playful characters/things for pre-readers.
    public static let symbols: [String] = [
        "face.smiling.fill", "star.fill", "heart.fill", "bolt.fill",
        "leaf.fill", "pawprint.fill", "crown.fill", "flame.fill",
        "hare.fill", "tortoise.fill", "ladybug.fill", "fish.fill",
        "sun.max.fill", "moon.stars.fill", "cloud.fill", "sparkles"
    ]

    /// Bright, distinct avatar background colors (index into this wraps).
    public static let colors: [Color] = [
        Color(red: 0.98, green: 0.45, blue: 0.16), // orange
        Color(red: 0.24, green: 0.55, blue: 0.90), // blue
        Color(red: 0.55, green: 0.36, blue: 0.86), // purple
        Color(red: 0.20, green: 0.66, blue: 0.39), // green
        Color(red: 0.93, green: 0.28, blue: 0.44), // pink
        Color(red: 0.95, green: 0.68, blue: 0.15), // amber
        Color(red: 0.16, green: 0.66, blue: 0.66), // teal
        Color(red: 0.90, green: 0.36, blue: 0.20)  // coral
    ]

    public static func symbol(_ index: Int) -> String {
        symbols[((index % symbols.count) + symbols.count) % symbols.count]
    }

    public static func color(_ index: Int) -> Color {
        colors[((index % colors.count) + colors.count) % colors.count]
    }
}

/// Circular avatar badge — symbol on a colored disc.
public struct AvatarView: View {
    let symbol: String
    let colorIndex: Int
    let size: CGFloat

    public init(symbol: String, colorIndex: Int, size: CGFloat = 44) {
        self.symbol = symbol
        self.colorIndex = colorIndex
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AvatarCatalog.color(colorIndex),
                            AvatarCatalog.color(colorIndex).opacity(0.75)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Image(systemName: symbol)
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: AvatarCatalog.color(colorIndex).opacity(0.35), radius: size * 0.12, y: size * 0.06)
    }
}
