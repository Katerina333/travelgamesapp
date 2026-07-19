import XCTest
import CoreKit
@testable import GameEngine

final class EligibilityTests: XCTestCase {
    private func player(_ name: String, band: AgeBand, driver: Bool = false, napping: Bool = false) -> PlayerContext {
        PlayerContext(id: UUID(), name: name, ageBand: band, isDriver: driver, isNapping: napping)
    }

    private func manifest(
        driverSafe: Bool = true,
        scope: ContentScope = .youngestInRound,
        bands: ClosedRange<AgeBand> = .preschool ... .adult,
        minPlayers: Int = 1,
        modes: Set<TravelMode> = [.car, .plane],
        quietSafe: Bool = true
    ) -> GameManifest {
        GameManifest(
            id: "test", nameKey: "test", icon: "star", minPlayers: minPlayers,
            ageBands: bands, driverSafe: driverSafe, screenLevel: .none,
            travelModes: modes, contentScope: scope, quietModeSafe: quietSafe
        )
    }

    // §1.2 — driver excluded from screen games, allowed in audio games.
    func testDriverExcludedFromNonDriverSafeGames() {
        let players = [
            player("Parent", band: .adult, driver: true),
            player("Kid", band: .early)
        ]
        let screenGame = manifest(driverSafe: false)
        let audioGame = manifest(driverSafe: true)

        XCTAssertEqual(PlayerEligibility.eligiblePlayers(players, for: screenGame).map(\.name), ["Kid"])
        XCTAssertEqual(PlayerEligibility.eligiblePlayers(players, for: audioGame).count, 2)
    }

    // §1.5 — napping players drop out of eligibility.
    func testNappingPlayersExcluded() {
        let players = [player("Kid", band: .preschool, napping: true), player("Teen", band: .teen)]
        XCTAssertEqual(PlayerEligibility.eligiblePlayers(players, for: manifest()).map(\.name), ["Teen"])
    }

    // §1.5 critical rule — guessing games cap at youngest in round.
    func testYoungestInRoundScoping() {
        let littleOne = player("Little", band: .preschool)
        let teen = player("Teen", band: .teen)
        let band = ContentScoping.effectiveBand(
            scope: .youngestInRound,
            players: [littleOne, teen],
            activePlayer: teen
        )
        XCTAssertEqual(band, .preschool)
    }

    // §1.5 — solo-performance games scale to the active player.
    func testActivePlayerScoping() {
        let littleOne = player("Little", band: .preschool)
        let teen = player("Teen", band: .teen)
        let band = ContentScoping.effectiveBand(
            scope: .activePlayer,
            players: [littleOne, teen],
            activePlayer: teen
        )
        XCTAssertEqual(band, .teen)
    }

    // §1.5 — napping youngest no longer caps content; recalculates upward.
    func testNappingYoungestRaisesContentCap() {
        let littleOne = player("Little", band: .preschool, napping: true)
        let tween = player("Tween", band: .tween)
        let band = ContentScoping.effectiveBand(
            scope: .youngestInRound,
            players: [littleOne, tween],
            activePlayer: tween
        )
        XCTAssertEqual(band, .tween)
    }

    // §1.4 — travel-mode filtering and quiet mode.
    func testTravelModeAndQuietModeFiltering() {
        let players = [player("Kid", band: .early)]
        let carOnly = manifest(modes: [.car])
        let loudGame = manifest(quietSafe: false)

        XCTAssertFalse(PlayerEligibility.isPlayable(carOnly, players: players, mode: .plane))
        XCTAssertTrue(PlayerEligibility.isPlayable(carOnly, players: players, mode: .car))
        XCTAssertFalse(PlayerEligibility.isPlayable(loudGame, players: players, mode: .plane, quietMode: true))
        XCTAssertTrue(PlayerEligibility.isPlayable(loudGame, players: players, mode: .plane, quietMode: false))
    }

    func testMinPlayersEnforced() {
        let players = [player("Solo", band: .early)]
        XCTAssertFalse(PlayerEligibility.isPlayable(manifest(minPlayers: 2), players: players, mode: .car))
    }

    func testSessionScoringAndRotation() {
        let a = player("A", band: .early)
        let b = player("B", band: .tween)
        let session = GameSession(manifest: manifest(), players: [a, b])

        session.apply(.points(playerID: a.id, amount: 5))
        session.apply(.points(playerID: a.id, amount: 2))
        session.apply(.roundCompleted)

        XCTAssertEqual(session.scores[a.id], 7)
        XCTAssertEqual(session.activePlayer?.id, b.id)

        session.apply(.roundCompleted)
        XCTAssertEqual(session.activePlayer?.id, a.id)

        session.apply(.gameEnded)
        XCTAssertTrue(session.isFinished)
    }
}
