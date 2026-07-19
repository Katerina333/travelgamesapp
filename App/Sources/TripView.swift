import SwiftUI
import SwiftData
import CoreKit
import GameEngine
import TripKit
import DesignSystem

/// Trip hub: game board, leaderboard, and lifecycle controls (§2.2).
struct TripView: View {
    let trip: Trip

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    private var tokens: ThemeTokens {
        themeManager.tokens(systemDark: colorScheme == .dark)
    }

    private var manifests: [GameManifest] {
        trip.gameBoard.compactMap { GameRegistry.shared.game(id: $0)?.manifest }
    }

    var body: some View {
        List {
            Section("trip.games") {
                if manifests.isEmpty {
                    Text("trip.games.empty")
                        .foregroundStyle(tokens.contentSecondary)
                }
                ForEach(manifests) { manifest in
                    if let game = GameRegistry.shared.game(id: manifest.id) {
                        NavigationLink {
                            GameHostView(trip: trip, game: game)
                        } label: {
                            gameRow(manifest)
                        }
                        .accessibilityIdentifier("row.game.\(manifest.id)")
                    }
                }
            }

            Section("trip.leaderboard") {
                ForEach(
                    Leaderboard.ranked(travelers: trip.travelers, sessions: trip.sessions),
                    id: \.traveler.id
                ) { entry in
                    HStack(spacing: Spacing.m) {
                        Image(systemName: entry.traveler.avatar)
                            .foregroundStyle(tokens.accentPrimary)
                        Text(verbatim: entry.traveler.name)
                        Spacer()
                        Text(verbatim: "\(entry.points)")
                            .bold()
                            .accessibilityIdentifier("leaderboard.points.\(entry.traveler.name)")
                    }
                }
            }
        }
        .navigationTitle(trip.destinationName.map { Text(verbatim: $0) } ?? Text("trip.title"))
        .toolbar {
            if trip.status == .active || trip.status == .paused {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("trip.complete") {
                        TripStateMachine.transition(trip, to: .completed)
                        try? context.save()
                        dismiss()
                    }
                    .accessibilityIdentifier("btn.completeTrip")
                }
            }
        }
    }

    private func gameRow(_ manifest: GameManifest) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: manifest.icon)
                .foregroundStyle(tokens.accentPrimary)
                .frame(width: 28)
            Text(LocalizedStringKey(manifest.nameKey))
            Spacer()
            if hasOpenSession(manifest.id) {
                Text("trip.status.inProgress")
                    .font(.caption)
                    .foregroundStyle(tokens.accentWarning)
            }
        }
    }

    private func hasOpenSession(_ gameID: String) -> Bool {
        trip.sessions.contains { $0.gameID == gameID && $0.endedAt == nil }
    }
}
