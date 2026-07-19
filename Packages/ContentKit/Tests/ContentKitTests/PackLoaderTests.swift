import XCTest
import CoreKit
@testable import ContentKit

final class PackLoaderTests: XCTestCase {
    // §4.4 — regional fallback chains.
    func testLocaleFallbackChains() {
        XCTAssertEqual(PackLoader.localeFallbackChain(for: "en-GB"), ["en-GB", "en"])
        XCTAssertEqual(PackLoader.localeFallbackChain(for: "en-AU"), ["en-AU", "en"])
        XCTAssertEqual(PackLoader.localeFallbackChain(for: "fr-CA"), ["fr-CA", "fr-FR", "fr"])
        XCTAssertEqual(PackLoader.localeFallbackChain(for: "uk"), ["uk"])
        XCTAssertEqual(PackLoader.localeFallbackChain(for: "zh-Hans"), ["zh-Hans", "zh"])
    }

    // en-GB falls back to the bundled en pack.
    func testLoadsBundledPackViaFallback() throws {
        let pack = PackLoader.loadPack(gameID: "roadbingo", locale: "en-GB", in: .module)
        let loaded = try XCTUnwrap(pack, "roadbingo en pack should load via en-GB → en fallback")
        XCTAssertEqual(loaded.gameID, "roadbingo")
        XCTAssertEqual(loaded.locale, "en")
        XCTAssertFalse(loaded.entries.isEmpty)
    }

    func testMissingPackReturnsNil() {
        XCTAssertNil(PackLoader.loadPack(gameID: "nonexistent", locale: "en", in: .module))
    }

    // §1.5 — entries filtered by the capped band.
    func testEntriesCappedAtBand() {
        let pack = ContentPack(
            id: "p", gameID: "g", locale: "en", version: 1,
            entries: [
                .init(text: "cat"),
                .init(text: "water tower", bands: [.early, .tween]),
                .init(text: "influencer", bands: [.teen, .adult])
            ]
        )
        let forPreschool = pack.entries(cappedAt: .preschool).map(\.text)
        XCTAssertEqual(forPreschool, ["cat"])

        let forTween = pack.entries(cappedAt: .tween).map(\.text)
        XCTAssertEqual(forTween, ["cat", "water tower"])
    }
}
