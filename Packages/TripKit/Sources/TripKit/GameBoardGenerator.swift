import Foundation
import CoreKit
import GameEngine

/// Assembles the personalised game board for a trip (§2.1 step 3): filters
/// manifests by travel mode, eligibility, and age overlap, then orders by fit.
public enum GameBoardGenerator {
    public static func recommendedManifests(
        from manifests: [GameManifest],
        players: [PlayerContext],
        mode: TravelMode,
        quietMode: Bool = false
    ) -> [GameManifest] {
        manifests
            .filter { PlayerEligibility.isPlayable($0, players: players, mode: mode, quietMode: quietMode) }
            .sorted {
                let a = fitScore($0, players: players)
                let b = fitScore($1, players: players)
                return a == b ? $0.id < $1.id : a > b
            }
    }

    /// Fraction of the awake group that can actually play (eligible AND inside
    /// the manifest's age range) — games that include more of the car rank higher.
    static func fitScore(_ manifest: GameManifest, players: [PlayerContext]) -> Double {
        let awake = players.filter { !$0.isNapping }
        guard !awake.isEmpty else { return 0 }
        let playable = PlayerEligibility.eligiblePlayers(awake, for: manifest)
            .filter { manifest.ageBands.contains($0.ageBand) }
        return Double(playable.count) / Double(awake.count)
    }
}

/// Maps SwiftData travelers to engine-facing player contexts.
public extension Traveler {
    var playerContext: PlayerContext {
        PlayerContext(id: id, name: name, ageBand: ageBand, isDriver: isDriver, isNapping: isNapping)
    }
}
