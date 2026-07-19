import SwiftUI
import CoreKit
import GameEngine
import ContentKit
import DesignSystem

struct BingoBoardView: View {
    let session: GameSession
    let packGameID: String

    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var state: BingoState?
    @State private var pendingCell: PendingCell?
    @State private var packMissing = false

    struct PendingCell: Identifiable {
        let index: Int
        var id: Int { index }
    }

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }

    private var spotters: [PlayerContext] {
        PlayerEligibility.eligiblePlayers(session.players, for: session.manifest)
    }

    var body: some View {
        Group {
            if let state {
                board(state)
            } else if packMissing {
                Text("bingo.packMissing")
                    .foregroundStyle(tokens.contentSecondary)
                    .padding(Spacing.l)
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: load)
        .sheet(item: $pendingCell) { cell in
            spotterPicker(for: cell.index)
        }
    }

    private func board(_ state: BingoState) -> some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                if state.isComplete {
                    completionCard
                }
                let columns = Array(
                    repeating: GridItem(.flexible(), spacing: Spacing.s),
                    count: state.gridSize
                )
                LazyVGrid(columns: columns, spacing: Spacing.s) {
                    ForEach(Array(state.items.enumerated()), id: \.offset) { index, item in
                        cellButton(index: index, item: item, marked: state.marks[index] != nil)
                    }
                }
                .padding(.horizontal, Spacing.m)
            }
            .padding(.vertical, Spacing.m)
        }
    }

    private func cellButton(index: Int, item: String, marked: Bool) -> some View {
        Button {
            tap(index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.s)
                    .fill(marked ? tokens.accentSuccess.opacity(0.3) : tokens.surfaceCard)
                VStack(spacing: Spacing.xs) {
                    if marked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(tokens.accentSuccess)
                    }
                    Text(verbatim: item)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(tokens.contentPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                }
                .padding(Spacing.xs)
            }
            .frame(minHeight: 72)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bingo.cell.\(index)")
        .accessibilityValue(marked ? "marked" : "unmarked")
        .accessibilityLabel(Text(verbatim: item))
    }

    private var completionCard: some View {
        VStack(spacing: Spacing.m) {
            Text("bingo.completed")
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(tokens.accentSuccess)
            PrimaryButton("common.done", tokens: tokens) {
                session.apply(.gameEnded)
            }
            .accessibilityIdentifier("btn.bingoDone")
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity)
        .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.m))
        .padding(.horizontal, Spacing.m)
    }

    private func spotterPicker(for index: Int) -> some View {
        NavigationStack {
            List(spotters) { player in
                Button {
                    mark(index, by: player.id)
                    pendingCell = nil
                } label: {
                    HStack(spacing: Spacing.m) {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(tokens.accentPrimary)
                        Text(verbatim: player.name)
                            .foregroundStyle(tokens.contentPrimary)
                    }
                }
                .accessibilityIdentifier("btn.spotter.\(player.name)")
            }
            .navigationTitle("bingo.whoSpotted")
        }
        .presentationDetents([.medium])
    }

    private func load() {
        guard state == nil else { return }
        if let payload = session.resumePayload,
           let restored = try? JSONDecoder().decode(BingoState.self, from: payload) {
            state = restored
            return
        }
        guard let pack = PackLoader.loadBundledPack(gameID: packGameID) else {
            packMissing = true
            return
        }
        let fresh = BingoState.generate(from: pack, band: session.effectiveContentBand)
        state = fresh
        // Persist the generated board immediately so a force-quit before the
        // first mark still restores the same cells.
        persist(fresh)
    }

    private func tap(_ index: Int) {
        guard let current = state, current.marks[index] == nil, !current.isComplete else { return }
        switch spotters.count {
        case 0:
            return
        case 1:
            mark(index, by: spotters[0].id)
        default:
            pendingCell = PendingCell(index: index)
        }
    }

    private func mark(_ index: Int, by playerID: UUID) {
        guard var current = state, current.marks[index] == nil else { return }
        current.marks[index] = playerID
        state = current
        persist(current)
        session.apply(.points(playerID: playerID, amount: 1))
    }

    private func persist(_ state: BingoState) {
        if let data = try? JSONEncoder().encode(state) {
            session.saveState(data)
        }
    }
}
