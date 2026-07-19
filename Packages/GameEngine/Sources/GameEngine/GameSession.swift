import Foundation
import Observation
import CoreKit

/// Events a game emits while running; the engine folds them into scores.
public enum GameEvent: Sendable {
    case points(playerID: UUID, amount: Int)
    case roundCompleted
    case gameEnded
}

/// Live runtime state for one game round. Mutations go through methods so the
/// host's persistence hook observes every change (§2.2 zero-data-loss rule).
@Observable
public final class GameSession {
    public let manifest: GameManifest
    public private(set) var players: [PlayerContext]
    public private(set) var scores: [UUID: Int]
    public var activePlayerIndex: Int
    public private(set) var isFinished: Bool
    /// Opaque game-specific state blob; restored on resume, persisted by the
    /// host into `GameSessionRecord.resumeState` so a killed app resumes at
    /// the exact round.
    public private(set) var resumePayload: Data?
    /// Host persistence hook — called after every mutation.
    @ObservationIgnored public var onChange: (() -> Void)?

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

    public init(
        manifest: GameManifest,
        players: [PlayerContext],
        scores: [UUID: Int] = [:],
        activePlayerIndex: Int = 0,
        resumePayload: Data? = nil
    ) {
        self.manifest = manifest
        self.players = players
        self.scores = scores
        self.activePlayerIndex = activePlayerIndex
        self.isFinished = false
        self.resumePayload = resumePayload
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
        onChange?()
    }

    /// Games call this with their encoded internal state after every move.
    public func saveState(_ payload: Data) {
        resumePayload = payload
        onChange?()
    }

    public func advanceToNextPlayer() {
        guard !players.isEmpty else { return }
        activePlayerIndex = (activePlayerIndex + 1) % players.count
    }
}
