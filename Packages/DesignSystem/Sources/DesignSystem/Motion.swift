import SwiftUI

/// Spring scale-down on press — makes every tap feel responsive (§5.2 motion).
public struct BouncyButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

public extension View {
    /// A gentle continuous bobbing animation for hero elements.
    func bobbing(_ active: Bool = true, distance: CGFloat = 6) -> some View {
        modifier(BobbingModifier(active: active, distance: distance))
    }
}

struct BobbingModifier: ViewModifier {
    let active: Bool
    let distance: CGFloat
    @State private var up = false
    func body(content: Content) -> some View {
        content
            .offset(y: active && up ? -distance : 0)
            .animation(active ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: up)
            .onAppear { if active { up = true } }
    }
}

/// A burst of confetti for wins and points (§5.2). Respects Reduce Motion.
public struct ConfettiView: View {
    let trigger: Int
    let colors: [Color]

    public init(trigger: Int, colors: [Color]) {
        self.trigger = trigger
        self.colors = colors
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        ZStack {
            if !reduceMotion {
                ForEach(0..<40, id: \.self) { i in
                    ConfettiPiece(index: i, trigger: trigger, color: colors[i % colors.count])
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiPiece: View {
    let index: Int
    let trigger: Int
    let color: Color

    @State private var animate = false

    // Deterministic per-piece spread so no Math.random is needed.
    private var angle: Double { Double(index) / 40 * 2 * .pi }
    private var distance: CGFloat { 120 + CGFloat(index % 7) * 26 }
    private var dx: CGFloat { cos(angle) * distance }
    private var dy: CGFloat { sin(angle) * distance + 40 }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 9, height: 13)
            .rotationEffect(.degrees(animate ? Double(index) * 40 : 0))
            .offset(x: animate ? dx : 0, y: animate ? dy : -20)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 0.6 : 1)
            .onChange(of: trigger) { _, _ in
                animate = false
                withAnimation(.easeOut(duration: 0.9)) { animate = true }
            }
    }
}

/// An animated "+N" that floats up and fades — used when a player scores.
public struct ScorePop: View {
    let text: String
    let color: Color
    @State private var shown = false

    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(verbatim: text)
            .font(.system(.title, design: .rounded).bold())
            .foregroundStyle(color)
            .offset(y: shown ? -60 : 0)
            .opacity(shown ? 0 : 1)
            .scaleEffect(shown ? 1.4 : 0.6)
            .onAppear { withAnimation(.easeOut(duration: 0.9)) { shown = true } }
    }
}
