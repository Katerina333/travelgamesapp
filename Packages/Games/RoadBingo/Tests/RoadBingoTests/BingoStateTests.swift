import XCTest
import CoreKit
import ContentKit
@testable import RoadBingo

final class BingoStateTests: XCTestCase {
    private func makePack() -> ContentPack {
        var entries: [ContentPack.Entry] = (1...20).map { .init(text: "item\($0)") }
        entries.append(.init(text: "teen-only", bands: [.teen, .adult]))
        return ContentPack(id: "p", gameID: "roadbingo", locale: "en", version: 1, entries: entries)
    }

    // §1.5 — a preschool cap builds a 3×3 board and drops teen-only items.
    func testPreschoolBoardIsSmallAndAgeCapped() {
        let state = BingoState.generate(from: makePack(), band: .preschool)
        XCTAssertEqual(state.gridSize, 3)
        XCTAssertEqual(state.items.count, 9)
        XCTAssertFalse(state.items.contains("teen-only"))
    }

    func testOlderBoardIsFourByFour() {
        let state = BingoState.generate(from: makePack(), band: .tween)
        XCTAssertEqual(state.gridSize, 4)
        XCTAssertEqual(state.items.count, 16)
    }

    func testSmallPackFallsBackToThreeByThree() {
        let tiny = ContentPack(
            id: "p", gameID: "g", locale: "en", version: 1,
            entries: (1...10).map { .init(text: "i\($0)") }
        )
        let state = BingoState.generate(from: tiny, band: .adult)
        XCTAssertEqual(state.gridSize, 3)
        XCTAssertEqual(state.items.count, 9)
    }

    // §2.2 — state round-trips through Codable identically (resumeState blob).
    func testCodableRoundTrip() throws {
        var state = BingoState.generate(from: makePack(), band: .early)
        let spotter = UUID()
        state.marks[3] = spotter
        state.marks[7] = spotter

        let data = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(BingoState.self, from: data)
        XCTAssertEqual(restored, state)
        XCTAssertEqual(restored.marks[3], spotter)
        XCTAssertEqual(restored.items, state.items)
    }

    func testCompletionDetection() {
        var state = BingoState(gridSize: 3, items: ["a", "b"])
        XCTAssertFalse(state.isComplete)
        state.marks[0] = UUID()
        state.marks[1] = UUID()
        XCTAssertTrue(state.isComplete)
    }

    // The bundled packs both games rely on must exist and fill a 4×4 board.
    func testBundledPacksExist() {
        for gameID in ["roadbingo", "cabinbingo"] {
            let pack = PackLoader.loadBundledPack(gameID: gameID, localeIdentifier: "en-US")
            XCTAssertNotNil(pack, "\(gameID) pack missing")
            XCTAssertGreaterThanOrEqual(pack?.entries.count ?? 0, 16)
        }
    }
}
