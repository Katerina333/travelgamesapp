import Foundation
import Observation
import CoreKit

/// Events a game emits while running; the engine folds them into scores.
public enum GameEvent: Sendable {
    case points(playerID: UUID, amount: Int)
    case roundCompleted
    case gameEnded
}

/// Live runtime state for one game round. Mutations go through methods so
/// persistence hooks can observe every change (§2.2 zero-data-loss rule).
@Observable
public final class GameSession {
    public let manifest: GameManifest
    public private(set) var players: [PlayerContext]
    public private(set) var scores: [UUID: Int]
    public var activePlayerIndex: Int
    public private(set) var isFinished: Bool

    public var activePlayer: PlayerContext? {
        players.indices.contains(activePlayerIndex) ? players[activePlayerIndex] : nil
    }

    /// The age band content must be drawn from for the current prompt (§1.5).
    public var effectiveContentBand: AgeBand {
        ContentScoping.effectiveBand(
            scope: manifest.contentScope,
            players: players,
            activePlayer: activePlayer
        )
    }

    public init(manifest: GameManifest, players: [PlayerContext], scores: [UUID: Int] = [:], activePlayerIndex: Int = 0) {
        self.manifest = manifest
        self.players = players
        self.scores = scores
        self.activePlayerIndex = activePlayerIndex
        self.isFinished = false
    }

    public func apply(_ event: GameEvent) {
        switch event {
        case .points(let playerID, let amount):
            scores[playerID, default: 0] += amount
        case .roundCompleted:
            advanceToNextPlayer()
        case .gameEnded:
            isFinished = true
        }
    }

    public func advanceToNextPlayer() {
        guard !players.isEmpty else { return }
        activePlayerIndex = (activePlayerIndex + 1) % players.count
    }
}
