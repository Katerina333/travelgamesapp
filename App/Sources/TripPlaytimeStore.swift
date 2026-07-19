import Foundation
import SwiftData
import CoreKit
import PaywallKit

/// SwiftData-backed persistence for the playtime meter (§6): accumulated
/// seconds live on the Trip so they survive relaunch. Uses its own short-lived
/// contexts, touching only `playtimeSeconds`.
final class TripPlaytimeStore: PlaytimeStore, @unchecked Sendable {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func loadAccumulatedSeconds(tripID: UUID) -> Double {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.id == tripID })
        return (try? context.fetch(descriptor).first?.playtimeSeconds) ?? 0
    }

    func save(accumulatedSeconds: Double, tripID: UUID) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.id == tripID })
        guard let trip = try? context.fetch(descriptor).first else { return }
        trip.playtimeSeconds = accumulatedSeconds
        try? context.save()
    }
}
