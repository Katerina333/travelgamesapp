import SwiftUI
import CoreKit
import GameEngine
import ContentKit
import DesignSystem

/// Would You Rather — the active player picks between two options; everyone
/// reacts. Works in every travel mode, capped at the youngest so the dilemmas
/// are relatable to all (§1.5). Screen-light: a passenger reads it aloud.
public struct WouldYouRatherGame: TripGame {
    public let manifest = GameManifest(
        id: "wouldyourather",
        nameKey: "game.wouldyourather.name",
        icon: "arrow.triangle.branch",
        minPlayers: 1,
        ageBands: .preschool ... .adult,
        driverSafe: true,
        screenLevel: .minimal,
        travelModes: Set(TravelMode.allCases),
        contentScope: .youngestInRound
    )

    public init() {}

    public func makeSetupView(session: GameSession) -> AnyView {
        AnyView(WouldYouRatherView(session: session))
    }

    public func makePlayView(session: GameSession) -> AnyView {
        AnyView(WouldYouRatherView(session: session))
    }
}

struct Dilemma: Codable, Equatable {
    let optionA: String
    let optionB: String
}

struct WYRState: Codable, Equatable {
    var dilemmas: [Dilemma]
    var index: Int = 0
    var picked: Int? = nil // 0 = A, 1 = B

    static func build(from pack: ContentPack, band: AgeBand) -> WYRState {
        let dilemmas = pack.entries(cappedAt: band).compactMap { e -> Dilemma? in
            guard let b = e.optionB else { return nil }
            return Dilemma(optionA: e.text, optionB: b)
        }.shuffled()
        return WYRState(dilemmas: dilemmas)
    }
}

struct WouldYouRatherView: View {
    let session: GameSession
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var state: WYRState?
    @State private var missing = false

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }
    private var current: Dilemma? {
        guard let s = state, s.dilemmas.indices.contains(s.index) else { return nil }
        return s.dilemmas[s.index]
    }

    var body: some View {
        Group {
            if let dilemma = current {
                content(dilemma)
            } else if missing || state?.dilemmas.isEmpty == true {
                GameMessage(key: "wyr.empty", tokens: tokens)
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: load)
    }

    private func content(_ dilemma: Dilemma) -> some View {
        VStack(spacing: Spacing.l) {
            if let player = session.activePlayer {
                Text("wyr.turn \(player.name)")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(tokens.contentSecondary)
            }
            Text("wyr.title")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundStyle(tokens.contentPrimary)

            optionCard(dilemma.optionA, index: 0, colorIndex: 1)
            Text("wyr.or")
                .font(.system(.headline, design: .rounded).bold())
                .foregroundStyle(tokens.accentPrimary)
            optionCard(dilemma.optionB, index: 1, colorIndex: 4)

            Spacer()

            if state?.picked != nil {
                PrimaryButton("wyr.next", tokens: tokens, icon: "arrow.right") { next() }
                    .accessibilityIdentifier("btn.wyrNext")
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func optionCard(_ text: String, index: Int, colorIndex: Int) -> some View {
        let picked = state?.picked
        let isPicked = picked == index
        let dimmed = picked != nil && !isPicked
        return Button {
            pick(index)
        } label: {
            Text(verbatim: text)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(isPicked ? .white : tokens.contentPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 96)
                .padding(Spacing.m)
                .background(
                    isPicked ? AvatarCatalog.color(colorIndex) : tokens.surfaceCard,
                    in: RoundedRectangle(cornerRadius: Radius.l)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.l)
                        .strokeBorder(AvatarCatalog.color(colorIndex).opacity(0.4), lineWidth: 2)
                )
                .opacity(dimmed ? 0.5 : 1)
                .scaleEffect(isPicked ? 1.03 : 1)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(picked != nil)
        .accessibilityIdentifier("btn.wyrOption.\(index)")
    }

    private func load() {
        guard state == nil else { return }
        if let data = session.resumePayload, let restored = try? JSONDecoder().decode(WYRState.self, from: data) {
            state = restored
            return
        }
        guard let pack = PackLoader.loadBundledPack(gameID: "wouldyourather") else { missing = true; return }
        let fresh = WYRState.build(from: pack, band: session.effectiveContentBand)
        state = fresh
        persist(fresh)
    }

    private func pick(_ index: Int) {
        guard var s = state, s.picked == nil else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { s.picked = index }
        state = s
        if let player = session.activePlayer {
            session.apply(.points(playerID: player.id, amount: 1))
        }
        persist(s)
    }

    private func next() {
        guard var s = state else { return }
        s.picked = nil
        s.index += 1
        session.advanceToNextPlayer()
        if s.index >= s.dilemmas.count {
            s.dilemmas.shuffle()
            s.index = 0
        }
        withAnimation(.easeInOut) { state = s }
        persist(s)
    }

    private func persist(_ s: WYRState) {
        if let data = try? JSONEncoder().encode(s) { session.saveState(data) }
    }
}

/// Small shared empty-state view.
struct GameMessage: View {
    let key: LocalizedStringKey
    let tokens: ThemeTokens
    var body: some View {
        Text(key)
            .font(.system(.body, design: .rounded))
            .foregroundStyle(tokens.contentSecondary)
            .multilineTextAlignment(.center)
            .padding(Spacing.l)
    }
}
