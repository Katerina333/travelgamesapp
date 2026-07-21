import XCTest
import CoreKit
import ContentKit
@testable import Trivia

final class TriviaTests: XCTestCase {
    func testStateCodableRoundTrip() throws {
        var s = TriviaState()
        s.current = Question(text: "2+2?", choices: ["3", "4", "5"], answer: 1, band: 0)
        s.chosen = 1
        s.askedTexts = ["2+2?"]
        let data = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(TriviaState.self, from: data), s)
    }

    func testBundledPackHasWellFormedQuestions() throws {
        let pack = try XCTUnwrap(PackLoader.loadBundledPack(gameID: "trivia", localeIdentifier: "en-US"))
        let questions = pack.entries.filter { $0.choices != nil }
        XCTAssertGreaterThanOrEqual(questions.count, 10)
        for q in questions {
            let choices = try XCTUnwrap(q.choices)
            let answer = try XCTUnwrap(q.answer)
            XCTAssertTrue(choices.indices.contains(answer), "answer index out of range for '\(q.text)'")
            XCTAssertGreaterThanOrEqual(choices.count, 2)
        }
    }

    // §1.5 — a preschool cap must not surface teen/adult questions.
    func testAgeCappingFiltersHarderQuestions() {
        let pack = ContentPack(id: "p", gameID: "trivia", locale: "en", version: 1, entries: [
            .init(text: "easy", bands: [.preschool, .early], choices: ["a", "b"], answer: 0),
            .init(text: "hard", bands: [.teen, .adult], choices: ["a", "b"], answer: 1)
        ])
        let easy = pack.entries(cappedAt: .preschool).map(\.text)
        XCTAssertEqual(easy, ["easy"])
    }
}
