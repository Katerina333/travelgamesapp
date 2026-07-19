import Foundation
import CoreKit

/// How much the game asks players to look at the screen (§1.1).
public enum ScreenLevel: String, Codable, Sendable {
    case none
    case minimal
    case shortBurst
    case passAround
}

/// Content-selection rule (§1.5, critical): guessing games cap content at the
/// youngest player in the round; solo-performance games scale to the active player.
public enum ContentScope: String, Codable, Sendable {
    case youngestInRound
    case activePlayer
}

/// Device capabilities a game needs; checked before the game is offered.
public enum GameCapability: String, Codable, Sendable {
    case microphone
    case gps
    case camera
}

/// Static description of a game. The Game Board generator and library UI read
/// only manifests — game code stays behind the `TripGame` protocol (§4.3).
public struct GameManifest: Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let icon: String
    public let minPlayers: Int
    public let maxPlayers: Int
    public let ageBands: ClosedRange<AgeBand>
    public let driverSafe: Bool
    public let screenLevel: ScreenLevel
    public let travelModes: Set<TravelMode>
    public let contentScope: ContentScope
    public let requiredCapabilities: Set<GameCapability>
    /// Whether the game stays available when Quiet Mode is on (§1.4).
    public let quietModeSafe: Bool

    public init(
        id: String,
        nameKey: String,
        icon: String,
        minPlayers: Int,
        maxPlayers: Int = 8,
        ageBands: ClosedRange<AgeBand>,
        driverSafe: Bool,
        screenLevel: ScreenLevel,
        travelModes: Set<TravelMode> = [.car, .plane],
        contentScope: ContentScope,
        requiredCapabilities: Set<GameCapability> = [],
        quietModeSafe: Bool = true
    ) {
        self.id = id
        self.nameKey = nameKey
        self.icon = icon
        self.minPlayers = minPlayers
        self.maxPlayers = maxPlayers
        self.ageBands = ageBands
        self.driverSafe = driverSafe
        self.screenLevel = screenLevel
        self.travelModes = travelModes
        self.contentScope = contentScope
        self.requiredCapabilities = requiredCapabilities
        self.quietModeSafe = quietModeSafe
    }
}
