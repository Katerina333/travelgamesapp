import SwiftUI
import CoreKit

/// Every game conforms to this protocol and ships as a self-contained package
/// (§4.3). Adding a game = new package + registry entry + content pack.
@MainActor
public protocol TripGame {
    var manifest: GameManifest { get }
    func makeSetupView(session: GameSession) -> AnyView
    func makePlayView(session: GameSession) -> AnyView
    func score(_ event: GameEvent, into session: GameSession)
}

public extension TripGame {
    /// Default scoring simply folds the event into the session.
    func score(_ event: GameEvent, into session: GameSession) {
        session.apply(event)
    }
}

/// Central registry of installed games. The board generator and library UI
/// read only `allManifests`.
@MainActor
public final class GameRegistry {
    public static let shared = GameRegistry()

    private var games: [String: any TripGame] = [:]

    public init() {}

    public func register(_ game: any TripGame) {
        games[game.manifest.id] = game
    }

    public func game(id: String) -> (any TripGame)? {
        games[id]
    }

    public var allManifests: [GameManifest] {
        games.values.map(\.manifest).sorted { $0.id < $1.id }
    }
}
