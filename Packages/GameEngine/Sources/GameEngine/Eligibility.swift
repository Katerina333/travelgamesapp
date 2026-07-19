import Foundation
import CoreKit

/// Player-eligibility rules: driver exclusion (§1.2) and napping (§1.5).
public enum PlayerEligibility {
    public static func eligiblePlayers(
        _ players: [PlayerContext],
        for manifest: GameManifest
    ) -> [PlayerContext] {
        players.filter { player in
            if player.isNapping { return false }
            if player.isDriver && !manifest.driverSafe { return false }
            return true
        }
    }

    /// A game is playable if enough eligible players remain and at least one
    /// eligible player's age band overlaps the manifest's range.
    public static func isPlayable(
        _ manifest: GameManifest,
        players: [PlayerContext],
        mode: TravelMode,
        quietMode: Bool = false
    ) -> Bool {
        guard manifest.travelModes.contains(mode) else { return false }
        if quietMode && !manifest.quietModeSafe { return false }
        let eligible = eligiblePlayers(players, for: manifest)
        guard eligible.count >= manifest.minPlayers else { return false }
        return eligible.contains { manifest.ageBands.contains($0.ageBand) }
    }
}

/// Content-scope resolution (§1.5 critical rule).
public enum ContentScoping {
    /// Guessing games: capped at the youngest non-napping participant.
    /// Solo-performance games: the active player's own band.
    public static func effectiveBand(
        scope: ContentScope,
        players: [PlayerContext],
        activePlayer: PlayerContext?
    ) -> AgeBand {
        switch scope {
        case .youngestInRound:
            let awake = players.filter { !$0.isNapping }
            return awake.map(\.ageBand).min() ?? activePlayer?.ageBand ?? .early
        case .activePlayer:
            return activePlayer?.ageBand ?? .early
        }
    }
}
