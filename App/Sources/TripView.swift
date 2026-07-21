import SwiftUI
import SwiftData
import CoreKit
import GameEngine
import TripKit
import DesignSystem

/// Trip hub: game board + leaderboard + lifecycle controls (§2.2).
struct TripView: View {
    let trip: Trip

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }

    private var manifests: [GameManifest] {
        trip.gameBoard.compactMap { GameRegistry.shared.game(id: $0)?.manifest }
    }

    private var ranked: [(traveler: Traveler, points: Int)] {
        Leaderboard.ranked(travelers: trip.travelers, sessions: trip.sessions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                leaderboardCard
                gamesSection
            }
            .padding(Spacing.l)
        }
        .background(tokens.backgroundPrimary)
        .navigationTitle(trip.destinationName.map { Text(verbatim: $0) } ?? Text("trip.title"))
        .navigationBarTitleDisplayMode(.large)
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

    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("trip.games")
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(tokens.contentPrimary)

            if manifests.isEmpty {
                Text("trip.games.empty")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(tokens.contentSecondary)
            }

            ForEach(Array(manifests.enumerated()), id: \.element.id) { index, manifest in
                if GameRegistry.shared.game(id: manifest.id) != nil {
                    NavigationLink {
                        if let game = GameRegistry.shared.game(id: manifest.id) {
                            GameHostView(trip: trip, game: game)
                        }
                    } label: {
                        GameCard(
                            titleKey: LocalizedStringKey(manifest.nameKey),
                            icon: manifest.icon,
                            colorIndex: index,
                            inProgress: hasOpenSession(manifest.id),
                            tokens: tokens
                        )
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityIdentifier("row.game.\(manifest.id)")
                }
            }
        }
    }

    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "trophy.fill").foregroundStyle(tokens.accentWarning)
                Text("trip.leaderboard")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundStyle(tokens.contentPrimary)
            }
            ForEach(Array(ranked.enumerated()), id: \.element.traveler.id) { rank, entry in
                HStack(spacing: Spacing.m) {
                    Text(verbatim: "\(rank + 1)")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundStyle(rank == 0 ? tokens.accentWarning : tokens.contentSecondary)
                        .frame(width: 22)
                    AvatarView(symbol: entry.traveler.avatar, colorIndex: entry.traveler.avatarColorIndex, size: 38)
                    Text(verbatim: entry.traveler.name)
                        .font(.system(.headline, design: .rounded).weight(.medium))
                        .foregroundStyle(tokens.contentPrimary)
                    if entry.traveler.isDriver && trip.travelMode.requiresDriver {
                        Image(systemName: "steeringwheel").font(.caption).foregroundStyle(tokens.contentSecondary)
                    }
                    Spacer()
                    Text(verbatim: "\(entry.points)")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(tokens.accentPrimary)
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("leaderboard.points.\(entry.traveler.name)")
                }
            }
        }
        .padding(Spacing.l)
        .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.l))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func hasOpenSession(_ gameID: String) -> Bool {
        trip.sessions.contains { $0.gameID == gameID && $0.endedAt == nil }
    }
}
