import XCTest
import CoreKit
import ContentKit
@testable import WouldYouRather

final class WYRStateTests: XCTestCase {
    func testBuildsOnlyDilemmasWithTwoOptions() {
        let pack = ContentPack(id: "p", gameID: "wouldyourather", locale: "en", version: 1, entries: [
            .init(text: "fly", optionB: "be invisible"),
            .init(text: "no option b here"),
            .init(text: "teen thing", bands: [.teen, .adult], optionB: "other teen thing"),
            .init(text: "pizza", optionB: "ice cream")
        ])
        let forKid = WYRState.build(from: pack, band: .preschool)
        XCTAssertEqual(forKid.dilemmas.count, 2) // fly/invisible + pizza/ice cream
        XCTAssertTrue(forKid.dilemmas.allSatisfy { !$0.optionB.isEmpty })

        let forTeen = WYRState.build(from: pack, band: .teen)
        XCTAssertEqual(forTeen.dilemmas.count, 3)
    }

    func testCodableRoundTrip() throws {
        var state = WYRState(dilemmas: [Dilemma(optionA: "a", optionB: "b")])
        state.picked = 1
        let data = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(WYRState.self, from: data)
        XCTAssertEqual(restored, state)
    }

    func testBundledPackExists() {
        let pack = PackLoader.loadBundledPack(gameID: "wouldyourather", localeIdentifier: "en-US")
        XCTAssertNotNil(pack)
        XCTAssertGreaterThanOrEqual(pack?.entries.count ?? 0, 8)
    }
}
