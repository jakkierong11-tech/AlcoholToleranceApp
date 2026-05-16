import XCTest
@testable import AlcoholToleranceApp

final class EmptyTest: XCTestCase {
    func test_nothing() {
        XCTAssertTrue(true)
    }

    func test_appModuleAccessible() {
        // Verify @testable import works
        let bac = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true,
            volumeML: 500, alcoholPercent: 5
        )
        XCTAssertGreaterThan(bac, 0)
    }
}
