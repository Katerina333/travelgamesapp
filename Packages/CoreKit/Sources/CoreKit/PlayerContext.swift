import Foundation

/// Lightweight, Sendable snapshot of a traveler used by the game engine —
/// keeps game logic decoupled from SwiftData models.
public struct PlayerContext: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let ageBand: AgeBand
    public let isDriver: Bool
    public let isNapping: Bool

    public init(id: UUID, name: String, ageBand: AgeBand, isDriver: Bool, isNapping: Bool = false) {
        self.id = id
        self.name = name
        self.ageBand = ageBand
        self.isDriver = isDriver
        self.isNapping = isNapping
    }
}
