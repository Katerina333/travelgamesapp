import Foundation
import CoreKit

/// Validates trip lifecycle transitions: scheduled → active ⇄ paused → completed (§2.2).
public enum TripStateMachine {
    public static func canTransition(from: TripStatus, to: TripStatus) -> Bool {
        switch (from, to) {
        case (.scheduled, .active),
             (.active, .paused),
             (.paused, .active),
             (.active, .completed),
             (.paused, .completed):
            return true
        default:
            return false
        }
    }

    /// Applies a transition to a trip, stamping timestamps. Returns false and
    /// leaves the trip untouched if the transition is invalid.
    @discardableResult
    public static func transition(_ trip: Trip, to newStatus: TripStatus, at date: Date = .now) -> Bool {
        guard canTransition(from: trip.status, to: newStatus) else { return false }
        if newStatus == .active && trip.startedAt == nil {
            trip.startedAt = date
        }
        if newStatus == .completed {
            trip.completedAt = date
        }
        trip.status = newStatus
        return true
    }
}
