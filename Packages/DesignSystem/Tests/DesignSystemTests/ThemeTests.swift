import XCTest
@testable import DesignSystem

final class ThemeTests: XCTestCase {
    // §5.1 — Auto follows system appearance; Light/Night are fixed.
    func testAutoFollowsSystem() {
        XCTAssertEqual(
            ThemeMode.auto.resolvedTokens(systemDark: true).backgroundPrimary,
            ThemeTokens.night.backgroundPrimary
        )
        XCTAssertEqual(
            ThemeMode.auto.resolvedTokens(systemDark: false).backgroundPrimary,
            ThemeTokens.light.backgroundPrimary
        )
        XCTAssertEqual(
            ThemeMode.night.resolvedTokens(systemDark: false).backgroundPrimary,
            ThemeTokens.night.backgroundPrimary
        )
        XCTAssertEqual(
            ThemeMode.light.resolvedTokens(systemDark: true).backgroundPrimary,
            ThemeTokens.light.backgroundPrimary
        )
    }
}
