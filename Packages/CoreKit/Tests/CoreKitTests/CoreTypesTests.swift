import XCTest
@testable import CoreKit

final class CoreTypesTests: XCTestCase {
    func testAgeBandFromAge() {
        XCTAssertEqual(AgeBand(age: 3), .preschool)
        XCTAssertEqual(AgeBand(age: 5), .preschool)
        XCTAssertEqual(AgeBand(age: 6), .early)
        XCTAssertEqual(AgeBand(age: 8), .early)
        XCTAssertEqual(AgeBand(age: 9), .tween)
        XCTAssertEqual(AgeBand(age: 12), .tween)
        XCTAssertEqual(AgeBand(age: 13), .teen)
        XCTAssertEqual(AgeBand(age: 17), .teen)
        XCTAssertEqual(AgeBand(age: 35), .adult)
    }

    func testAgeBandOrdering() {
        XCTAssertTrue(AgeBand.preschool < AgeBand.early)
        XCTAssertTrue(AgeBand.teen < AgeBand.adult)
        XCTAssertEqual([AgeBand.teen, .preschool, .tween].min(), .preschool)
    }

    func testSchemaContainerBuildsInMemory() throws {
        let container = try CoreSchema.container(inMemory: true)
        XCTAssertNotNil(container)
    }
}
