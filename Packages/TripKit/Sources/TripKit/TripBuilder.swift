import Foundation
import CoreKit
import GameEngine

/// Creates a trip with its personalised game board (§2.1 step 3). Quiet Mode
/// defaults on for plane and train trips — shared public space (§1.4).
public enum TripBuilder {
    public static func makeTrip(
        travelers: [Traveler],
        mode: TravelMode,
        length: TripLength,
        destinationName: String? = nil,
        manifests: [GameManifest],
        startNow: Bool = true,
        scheduledStart: Date? = nil,
        now: Date = .now
    ) -> Trip {
        let players = travelers.map(\.playerContext)
        let quiet = mode.defaultsToQuietMode
        let board = GameBoardGenerator
            .recommendedManifests(from: manifests, players: players, mode: mode, quietMode: quiet)
            .map(\.id)
        let trip = Trip(
            createdAt: now,
            scheduledStart: scheduledStart,
            travelMode: mode,
            status: .scheduled,
            length: length,
            destinationName: destinationName,
            quietMode: quiet,
            gameBoard: board,
            travelers: travelers
        )
        if startNow {
            TripStateMachine.transition(trip, to: .active, at: now)
        }
        return trip
    }
}

/// Aggregates per-game session scores into trip totals (§1.1 game 22).
public enum Leaderboard {
    public static func totals(sessions: [GameSessionRecord]) -> [UUID: Int] {
        sessions.reduce(into: [:]) { acc, session in
            for (travelerID, points) in session.scores {
                acc[travelerID, default: 0] += points
            }
        }
    }

    /// Ranked travelers, highest points first; ties broken by name for a
    /// stable display order.
    public static func ranked(
        travelers: [Traveler],
        sessions: [GameSessionRecord]
    ) -> [(traveler: Traveler, points: Int)] {
        let totals = totals(sessions: sessions)
        return travelers
            .map { (traveler: $0, points: totals[$0.id] ?? 0) }
            .sorted {
                $0.points == $1.points ? $0.traveler.name < $1.traveler.name : $0.points > $1.points
            }
    }
}
