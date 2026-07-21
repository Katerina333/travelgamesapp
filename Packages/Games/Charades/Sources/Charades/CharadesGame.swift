import SwiftUI
import CoreKit
import GameEngine
import ContentKit
import DesignSystem

/// Finger & Face Charades — the active player peeks the word, then acts it out
/// with fingers and facial expressions only (everyone's belted in). Guessers
/// must be able to guess it, so words are capped at the youngest (§1.5). The
/// driver is excluded (peeking/holding the phone).
public struct CharadesGame: TripGame {
    public let manifest = GameManifest(
        id: "charades",
        nameKey: "game.charades.name",
        icon: "theatermasks.fill",
        minPlayers: 2,
        ageBands: .preschool ... .adult,
        driverSafe: false,
        screenLevel: .shortBurst,
        travelModes: Set(TravelMode.allCases),
        contentScope: .youngestInRound
    )

    public init() {}

    public func makeSetupView(session: GameSession) -> AnyView {
        AnyView(CharadesView(session: session))
    }

    public func makePlayView(session: GameSession) -> AnyView {
        AnyView(CharadesView(session: session))
    }
}

enum CharadesPhase: String, Codable { case ready, peek, acting }

struct CharadesState: Codable, Equatable {
    var words: [String]
    var index: Int = 0
    var phase: CharadesPhase = .ready

    var word: String? { words.indices.contains(index) ? words[index] : nil }

    static func build(from pack: ContentPack, band: AgeBand) -> CharadesState {
        CharadesState(words: pack.entries(cappedAt: band).map(\.text).shuffled())
    }
}

struct CharadesView: View {
    let session: GameSession
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var state: CharadesState?
    @State private var missing = false

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }

    var body: some View {
        Group {
            if missing || state?.words.isEmpty == true {
                GameMessageC(key: "charades.empty", tokens: tokens)
            } else if let s = state, let word = s.word {
                switch s.phase {
                case .ready: readyView
                case .peek: peekView(word)
                case .acting: actingView
                }
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: load)
    }

    private var readyView: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            Image(systemName: "theatermasks.fill")
                .font(.system(size: 64))
                .foregroundStyle(tokens.accentPrimary)
                .bobbing()
            if let player = session.activePlayer {
                Text("charades.turn \(player.name)")
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundStyle(tokens.contentPrimary)
                    .multilineTextAlignment(.center)
            }
            Text("charades.instruction")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(tokens.contentSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.l)
            Spacer()
            PrimaryButton("charades.peek", tokens: tokens, icon: "eye.fill") {
                setPhase(.peek)
            }
            .accessibilityIdentifier("btn.charadesPeek")
        }
        .padding(Spacing.l)
    }

    private func peekView(_ word: String) -> some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            Text("charades.yourWord")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(tokens.contentSecondary)
            Text(verbatim: word)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(tokens.accentPrimary)
                .multilineTextAlignment(.center)
                .padding(Spacing.l)
                .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.l))
            Text("charades.actItOut")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(tokens.contentSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton("charades.startActing", tokens: tokens, icon: "hand.wave.fill") {
                setPhase(.acting)
            }
            .accessibilityIdentifier("btn.charadesAct")
        }
        .padding(Spacing.l)
    }

    private var actingView: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            Image(systemName: "hands.and.sparkles.fill")
                .font(.system(size: 56))
                .foregroundStyle(tokens.accentPrimary)
            Text("charades.actingNow")
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(tokens.contentPrimary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton("charades.guessed", tokens: tokens, icon: "checkmark.circle.fill") {
                resolve(guessed: true)
            }
            .accessibilityIdentifier("btn.charadesGuessed")
            GhostButton("charades.pass", tokens: tokens) {
                resolve(guessed: false)
            }
            .accessibilityIdentifier("btn.charadesPass")
        }
        .padding(Spacing.l)
    }

    private func load() {
        guard state == nil else { return }
        if let data = session.resumePayload, let restored = try? JSONDecoder().decode(CharadesState.self, from: data) {
            state = restored
            return
        }
        guard let pack = PackLoader.loadBundledPack(gameID: "charades") else { missing = true; return }
        let fresh = CharadesState.build(from: pack, band: session.effectiveContentBand)
        state = fresh
        persist(fresh)
    }

    private func setPhase(_ phase: CharadesPhase) {
        guard var s = state else { return }
        withAnimation(.easeInOut) { s.phase = phase }
        state = s
        persist(s)
    }

    private func resolve(guessed: Bool) {
        guard var s = state else { return }
        if guessed, let player = session.activePlayer {
            session.apply(.points(playerID: player.id, amount: 1))
        }
        s.index += 1
        if s.index >= s.words.count { s.words.shuffle(); s.index = 0 }
        s.phase = .ready
        session.advanceToNextPlayer()
        withAnimation(.easeInOut) { state = s }
        persist(s)
    }

    private func persist(_ s: CharadesState) {
        if let data = try? JSONEncoder().encode(s) { session.saveState(data) }
    }
}

struct GameMessageC: View {
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
