import SwiftUI
import CoreKit
import GameEngine
import ContentKit
import DesignSystem

/// Kids Trivia — a question is directed at one player and difficulty scales to
/// *that* player's age band (§1.5 activePlayer). Works in every travel mode.
public struct TriviaGame: TripGame {
    public let manifest = GameManifest(
        id: "trivia",
        nameKey: "game.trivia.name",
        icon: "lightbulb.fill",
        minPlayers: 1,
        ageBands: .preschool ... .adult,
        driverSafe: true,
        screenLevel: .minimal,
        travelModes: Set(TravelMode.allCases),
        contentScope: .activePlayer
    )

    public init() {}

    public func makeSetupView(session: GameSession) -> AnyView {
        AnyView(TriviaView(session: session))
    }

    public func makePlayView(session: GameSession) -> AnyView {
        AnyView(TriviaView(session: session))
    }
}

struct Question: Codable, Equatable {
    let text: String
    let choices: [String]
    let answer: Int
    /// The age band this question was drawn for (so a resumed round keeps it).
    let band: Int
}

struct TriviaState: Codable, Equatable {
    /// Remaining questions grouped nothing-fancy: we re-pick per active player
    /// from the pack at ask time, so state just tracks the current question.
    var current: Question?
    var chosen: Int? = nil
    var askedTexts: [String] = []
}

struct TriviaView: View {
    let session: GameSession
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var state = TriviaState()
    @State private var pack: ContentPack?
    @State private var missing = false

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }

    var body: some View {
        Group {
            if missing {
                GameMessageT(key: "trivia.empty", tokens: tokens)
            } else if let q = state.current {
                content(q)
            } else {
                ProgressView().onAppear(perform: setup)
            }
        }
        .onAppear(perform: setup)
    }

    private func content(_ q: Question) -> some View {
        VStack(spacing: Spacing.l) {
            if let player = session.activePlayer {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "person.fill")
                    Text("trivia.turn \(player.name)")
                }
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(tokens.accentPrimary)
            }

            Text(verbatim: q.text)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(tokens.contentPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.m)

            ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
                choiceButton(i, choice, q.answer)
            }

            Spacer()

            if state.chosen != nil {
                PrimaryButton("trivia.next", tokens: tokens, icon: "arrow.right") { nextTurn() }
                    .accessibilityIdentifier("btn.triviaNext")
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func choiceButton(_ index: Int, _ text: String, _ answer: Int) -> some View {
        let chosen = state.chosen
        let revealed = chosen != nil
        let isCorrect = index == answer
        let isChosen = chosen == index

        var bg: Color = tokens.surfaceCard
        var fg: Color = tokens.contentPrimary
        if revealed {
            if isCorrect { bg = tokens.accentSuccess; fg = .white }
            else if isChosen { bg = Color(red: 0.90, green: 0.30, blue: 0.34); fg = .white }
        }

        return Button {
            choose(index)
        } label: {
            HStack {
                Text(verbatim: text)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                Spacer()
                if revealed && isCorrect { Image(systemName: "checkmark.circle.fill") }
                else if revealed && isChosen { Image(systemName: "xmark.circle.fill") }
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, Spacing.m)
            .background(bg, in: RoundedRectangle(cornerRadius: Radius.m))
            .overlay(RoundedRectangle(cornerRadius: Radius.m).strokeBorder(tokens.contentSecondary.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(revealed)
        .accessibilityIdentifier("btn.triviaChoice.\(index)")
    }

    private func setup() {
        guard state.current == nil, !missing else { return }
        if let data = session.resumePayload, let restored = try? JSONDecoder().decode(TriviaState.self, from: data) {
            state = restored
        }
        if pack == nil {
            pack = PackLoader.loadBundledPack(gameID: "trivia")
            if pack == nil { missing = true; return }
        }
        if state.current == nil { askNext() }
    }

    private func askNext() {
        guard let pack else { missing = true; return }
        let band = session.effectiveContentBand // activePlayer band
        let candidates = pack.entries(cappedAt: band).filter {
            $0.choices != nil && $0.answer != nil && !state.askedTexts.contains($0.text)
        }
        let pool = candidates.isEmpty
            ? pack.entries(cappedAt: band).filter { $0.choices != nil && $0.answer != nil }
            : candidates
        guard let entry = pool.shuffled().first, let choices = entry.choices, let answer = entry.answer else {
            missing = true; return
        }
        if candidates.isEmpty { state.askedTexts = [] }
        state.current = Question(text: entry.text, choices: choices, answer: answer, band: band.rawValue)
        state.chosen = nil
        state.askedTexts.append(entry.text)
        persist()
    }

    private func choose(_ index: Int) {
        guard state.chosen == nil, let q = state.current else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { state.chosen = index }
        if index == q.answer, let player = session.activePlayer {
            session.apply(.points(playerID: player.id, amount: 1))
        }
        persist()
    }

    private func nextTurn() {
        session.advanceToNextPlayer()
        state.current = nil
        askNext()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) { session.saveState(data) }
    }
}

struct GameMessageT: View {
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
