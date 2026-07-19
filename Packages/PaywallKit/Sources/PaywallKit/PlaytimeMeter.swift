import Foundation

/// Persistence hook for the meter — production wires this to SwiftData,
/// tests use an in-memory store. Accumulated seconds survive relaunch (§2.3).
public protocol PlaytimeStore: Sendable {
    func loadAccumulatedSeconds(tripID: UUID) -> Double
    func save(accumulatedSeconds: Double, tripID: UUID)
}

public enum MeterState: Equatable, Sendable {
    /// Under the warning threshold; remaining free seconds attached.
    case playing(remaining: Double)
    /// Within the last 2 minutes of free play (§9: gentle warning).
    case warning(remaining: Double)
    /// Free window exhausted — blocking paywall (§2.3).
    case locked
}

/// Accumulates game time only while a game is active — timestamp deltas, not
/// wall clock, so backgrounding can't cheat and rest stops aren't punished.
public actor PlaytimeMeter {
    public static let freeLimitSeconds: Double = 600      // 10 minutes
    public static let warningThresholdSeconds: Double = 120 // warn with 2 min left

    private let store: any PlaytimeStore
    private let tripID: UUID
    private var accumulated: Double
    private var activeSince: Date?

    public init(tripID: UUID, store: any PlaytimeStore) {
        self.tripID = tripID
        self.store = store
        self.accumulated = store.loadAccumulatedSeconds(tripID: tripID)
    }

    /// Call when a game becomes active.
    public func gameStarted(at date: Date = .now) {
        guard activeSince == nil else { return }
        activeSince = date
    }

    /// Call when a game stops (pause, end, app background). Persists.
    public func gamePaused(at date: Date = .now) {
        flush(at: date)
        store.save(accumulatedSeconds: accumulated, tripID: tripID)
    }

    /// Heartbeat persistence while playing (30-sec cadence in the app, §6).
    public func heartbeat(at date: Date = .now) {
        let wasActive = activeSince != nil
        flush(at: date)
        if wasActive { activeSince = date }
        store.save(accumulatedSeconds: accumulated, tripID: tripID)
    }

    public func totalSeconds(at date: Date = .now) -> Double {
        if let activeSince {
            return accumulated + date.timeIntervalSince(activeSince)
        }
        return accumulated
    }

    public func state(at date: Date = .now, isSubscriber: Bool = false) -> MeterState {
        if isSubscriber { return .playing(remaining: .infinity) }
        let remaining = Self.freeLimitSeconds - totalSeconds(at: date)
        if remaining <= 0 { return .locked }
        if remaining <= Self.warningThresholdSeconds { return .warning(remaining: remaining) }
        return .playing(remaining: remaining)
    }

    private func flush(at date: Date) {
        if let start = activeSince {
            accumulated += max(0, date.timeIntervalSince(start))
            activeSince = nil
        }
    }
}
