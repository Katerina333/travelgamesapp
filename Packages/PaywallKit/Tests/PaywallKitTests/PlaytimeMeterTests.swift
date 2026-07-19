import XCTest
@testable import PaywallKit

/// Thread-safe in-memory store standing in for the SwiftData-backed one.
final class MemoryStore: PlaytimeStore, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [UUID: Double] = [:]

    func loadAccumulatedSeconds(tripID: UUID) -> Double {
        lock.lock(); defer { lock.unlock() }
        return values[tripID] ?? 0
    }

    func save(accumulatedSeconds: Double, tripID: UUID) {
        lock.lock(); defer { lock.unlock() }
        values[tripID] = accumulatedSeconds
    }
}

final class PlaytimeMeterTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 100_000)

    // §2.3 — meter accumulates only while a game is active.
    func testAccumulatesOnlyWhileActive() async {
        let meter = PlaytimeMeter(tripID: UUID(), store: MemoryStore())
        await meter.gameStarted(at: t0)
        await meter.gamePaused(at: t0.addingTimeInterval(120))
        // Rest stop: 1 hour passes while paused — must not count.
        let afterRestStop = t0.addingTimeInterval(3_720)
        let total = await meter.totalSeconds(at: afterRestStop)
        XCTAssertEqual(total, 120, accuracy: 0.001)
    }

    // §2.3/§9 — playing → warning at 2 minutes left → locked at 10:00.
    func testStateThresholds() async {
        let meter = PlaytimeMeter(tripID: UUID(), store: MemoryStore())
        await meter.gameStarted(at: t0)

        if case .playing(let remaining) = await meter.state(at: t0.addingTimeInterval(60)) {
            XCTAssertEqual(remaining, 540, accuracy: 0.001)
        } else {
            XCTFail("Expected .playing at 1 minute in")
        }

        if case .warning(let remaining) = await meter.state(at: t0.addingTimeInterval(500)) {
            XCTAssertEqual(remaining, 100, accuracy: 0.001)
        } else {
            XCTFail("Expected .warning with 100s left")
        }

        let locked = await meter.state(at: t0.addingTimeInterval(600))
        XCTAssertEqual(locked, .locked)
    }

    // §2.3 — accumulated seconds survive app relaunch via the store.
    func testRelaunchSurvival() async {
        let store = MemoryStore()
        let tripID = UUID()

        let meter1 = PlaytimeMeter(tripID: tripID, store: store)
        await meter1.gameStarted(at: t0)
        await meter1.gamePaused(at: t0.addingTimeInterval(400))

        // "Relaunch": fresh meter instance from the same store.
        let meter2 = PlaytimeMeter(tripID: tripID, store: store)
        let total = await meter2.totalSeconds(at: t0.addingTimeInterval(9_999))
        XCTAssertEqual(total, 400, accuracy: 0.001)

        await meter2.gameStarted(at: t0.addingTimeInterval(10_000))
        let state = await meter2.state(at: t0.addingTimeInterval(10_200))
        XCTAssertEqual(state, .locked)
    }

    // Heartbeat persists progress without stopping the clock (§6).
    func testHeartbeatPersistsWithoutStoppingClock() async {
        let store = MemoryStore()
        let tripID = UUID()
        let meter = PlaytimeMeter(tripID: tripID, store: store)

        await meter.gameStarted(at: t0)
        await meter.heartbeat(at: t0.addingTimeInterval(30))
        XCTAssertEqual(store.loadAccumulatedSeconds(tripID: tripID), 30, accuracy: 0.001)

        // Clock kept running after heartbeat.
        let total = await meter.totalSeconds(at: t0.addingTimeInterval(45))
        XCTAssertEqual(total, 45, accuracy: 0.001)
    }

    func testSubscriberNeverLocked() async {
        let meter = PlaytimeMeter(tripID: UUID(), store: MemoryStore())
        await meter.gameStarted(at: t0)
        let state = await meter.state(at: t0.addingTimeInterval(99_999), isSubscriber: true)
        XCTAssertNotEqual(state, .locked)
        XCTAssertTrue(PaywallGate.canPlay(meterState: state))
        XCTAssertFalse(PaywallGate.canPlay(meterState: .locked))
    }

    func testParentalGateChallenge() {
        var rng = SystemRandomNumberGenerator()
        let challenge = ParentalGateChallenge.make(using: &rng)
        let parts = challenge.question.split(separator: "×").map { Int($0.trimmingCharacters(in: .whitespaces))! }
        XCTAssertEqual(parts[0] * parts[1], challenge.answer)
    }
}
