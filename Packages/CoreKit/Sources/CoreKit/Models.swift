import Foundation
import SwiftData

/// A person on the trip. Ages drive content banding (§1.5); exactly one
/// traveler per car trip is the driver (§1.2).
@Model
public final class Traveler {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var avatar: String
    public var age: Int
    public var isDriver: Bool
    public var isNapping: Bool
    public var interests: [String]

    public var ageBand: AgeBand { AgeBand(age: age) }

    public init(
        id: UUID = UUID(),
        name: String,
        avatar: String = "face.smiling",
        age: Int,
        isDriver: Bool = false,
        isNapping: Bool = false,
        interests: [String] = []
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.age = age
        self.isDriver = isDriver
        self.isNapping = isNapping
        self.interests = interests
    }
}

/// The core container entity (§2.2): travelers, game board, scores, playtime.
/// All state persists on every change so killing the app loses nothing.
@Model
public final class Trip {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var scheduledStart: Date?
    public var startedAt: Date?
    public var completedAt: Date?
    public var travelModeRaw: String
    public var statusRaw: String
    public var lengthRaw: String
    public var destinationName: String?
    public var quietMode: Bool
    /// Ordered game IDs making up the personalised game board.
    public var gameBoard: [String]
    /// Cumulative metered playtime in seconds (PaywallKit free-gate input).
    public var playtimeSeconds: Double

    @Relationship(deleteRule: .cascade) public var travelers: [Traveler]
    @Relationship(deleteRule: .cascade) public var sessions: [GameSessionRecord]

    public var travelMode: TravelMode {
        get { TravelMode(rawValue: travelModeRaw) ?? .car }
        set { travelModeRaw = newValue.rawValue }
    }

    public var status: TripStatus {
        get { TripStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }

    public var length: TripLength {
        get { TripLength(rawValue: lengthRaw) ?? .medium }
        set { lengthRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        scheduledStart: Date? = nil,
        travelMode: TravelMode = .car,
        status: TripStatus = .scheduled,
        length: TripLength = .medium,
        destinationName: String? = nil,
        quietMode: Bool = false,
        gameBoard: [String] = [],
        playtimeSeconds: Double = 0,
        travelers: [Traveler] = [],
        sessions: [GameSessionRecord] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.scheduledStart = scheduledStart
        self.startedAt = nil
        self.completedAt = nil
        self.travelModeRaw = travelMode.rawValue
        self.statusRaw = status.rawValue
        self.lengthRaw = length.rawValue
        self.destinationName = destinationName
        self.quietMode = quietMode
        self.gameBoard = gameBoard
        self.playtimeSeconds = playtimeSeconds
        self.travelers = travelers
        self.sessions = sessions
    }
}

/// One played round/session of a game inside a trip, with per-traveler points.
@Model
public final class GameSessionRecord {
    @Attribute(.unique) public var id: UUID
    public var gameID: String
    public var startedAt: Date
    public var endedAt: Date?
    /// Traveler ID → points earned in this session.
    public var scores: [UUID: Int]
    /// Opaque per-game state blob so a killed app resumes at the exact round.
    public var resumeState: Data?

    public init(
        id: UUID = UUID(),
        gameID: String,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        scores: [UUID: Int] = [:],
        resumeState: Data? = nil
    ) {
        self.id = id
        self.gameID = gameID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.scores = scores
        self.resumeState = resumeState
    }
}

/// Central SwiftData schema definition.
public enum CoreSchema {
    public static var models: [any PersistentModel.Type] {
        [Trip.self, Traveler.self, GameSessionRecord.self]
    }

    public static func container(at url: URL? = nil, inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(models)
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let url {
            config = ModelConfiguration(schema: schema, url: url)
        } else {
            config = ModelConfiguration(schema: schema)
        }
        return try ModelContainer(for: schema, configurations: [config])
    }
}
