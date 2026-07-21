import XCTest
import CoreKit
import ContentKit
@testable import Charades

final class CharadesTests: XCTestCase {
    func testStateCodableRoundTrip() throws {
        var s = CharadesState(words: ["cat", "dog", "airplane"])
        s.index = 1
        s.phase = .acting
        let data = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(CharadesState.self, from: data), s)
    }

    func testWordAccessorAndWrap() {
        let s = CharadesState(words: ["a", "b"], index: 0)
        XCTAssertEqual(s.word, "a")
        let past = CharadesState(words: ["a", "b"], index: 5)
        XCTAssertNil(past.word)
    }

    // §1.5 — words capped at youngest so guessers can guess.
    func testBuildRespectsBandCap() {
        let pack = ContentPack(id: "p", gameID: "charades", locale: "en", version: 1, entries: [
            .init(text: "cat"),
            .init(text: "influencer", bands: [.teen, .adult])
        ])
        let forKid = CharadesState.build(from: pack, band: .preschool)
        XCTAssertEqual(forKid.words, ["cat"])
    }

    func testBundledPackExists() {
        let pack = PackLoader.loadBundledPack(gameID: "charades", localeIdentifier: "en-US")
        XCTAssertNotNil(pack)
        XCTAssertGreaterThanOrEqual(pack?.entries.count ?? 0, 12)
    }
}
