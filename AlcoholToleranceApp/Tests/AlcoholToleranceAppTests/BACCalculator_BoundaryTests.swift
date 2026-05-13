import XCTest
@testable import AlcoholToleranceApp

/// BACCalculator 边界条件与极端值测试
/// 验证防御性编程和异常输入处理
final class BACCalculator_BoundaryTests: XCTestCase {

    var sut: BACCalculator.Type!

    override func setUp() {
        super.setUp()
        sut = BACCalculator.self
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 零值边界

    /// 测试体重为 0 时的防御性处理
    func test_calculateBAC_zeroWeight_returnsZeroSafely() {
        let bac = sut.calculateBAC(
            weightKg: 0.0, isMale: true,
            volumeML: 500.0, alcoholPercent: 5.0
        )

        XCTAssertEqual(bac, 0.0, accuracy: 0.001, "体重为 0 时应安全返回 0")
        XCTAssertFalse(bac.isNaN, "结果不应为 NaN")
        XCTAssertFalse(bac.isInfinite, "结果不应为无穷大")
    }

    /// 测试饮酒量为 0 时的 BAC 计算
    func test_calculateBAC_zeroVolume_returnsZero() {
        let bac = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: 0.0, alcoholPercent: 5.0
        )

        XCTAssertEqual(bac, 0.0, accuracy: 0.001, "未饮酒时 BAC 应为 0")
    }

    /// 测试酒精浓度为 0% 的 BAC 计算
    func test_calculateBAC_zeroAlcoholPercent_returnsZero() {
        let bac = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: 500.0, alcoholPercent: 0.0
        )

        XCTAssertEqual(bac, 0.0, accuracy: 0.001, "无酒精饮料 BAC 应为 0")
    }

    // MARK: - 负数输入

    /// 测试负数体重输入
    func test_calculateBAC_negativeWeight_returnsZero() {
        let bac = sut.calculateBAC(
            weightKg: -70.0, isMale: true,
            volumeML: 500.0, alcoholPercent: 5.0
        )

        XCTAssertEqual(bac, 0.0, accuracy: 0.001, "负数体重应返回 0")
    }

    /// 测试负数饮酒量输入
    func test_calculateBAC_negativeVolume_returnsZero() {
        let bac = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: -100.0, alcoholPercent: 5.0
        )

        XCTAssertEqual(bac, 0.0, accuracy: 0.001, "负数饮酒量应返回 0")
    }

    /// 测试负数酒精浓度输入
    func test_calculateBAC_negativeAlcoholPercent_returnsZero() {
        let bac = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: 500.0, alcoholPercent: -5.0
        )

        XCTAssertEqual(bac, 0.0, accuracy: 0.001, "负数酒精浓度应返回 0")
    }

    // MARK: - 极端值

    /// 测试极大体重下的 BAC（300kg）
    func test_calculateBAC_extremeWeight_returnsVeryLowBAC() {
        let bac = sut.calculateBAC(
            weightKg: 300.0, isMale: true,
            volumeML: 1000.0, alcoholPercent: 50.0
        )

        // 酒精克数 = 1000×0.5×0.789 = 394.5g
        // BAC = 394.5/(300000×0.68)×100 ≈ 0.193%
        let expectedBAC = (394.5 / (300000.0 * 0.68)) * 100.0
        XCTAssertEqual(bac, expectedBAC, accuracy: 0.01, "极大体重 BAC 计算不正确")
    }

    /// 测试极大饮酒量下的 BAC（5000ml 高度酒）
    func test_calculateBAC_extremeVolume_returnsHighBAC() {
        let bac = sut.calculateBAC(
            weightKg: 60.0, isMale: false,
            volumeML: 5000.0, alcoholPercent: 40.0
        )

        XCTAssertGreaterThan(bac, 1.0, "极大饮酒量下 BAC 应 > 1%")
        XCTAssertFalse(bac.isNaN, "结果不应为 NaN")
        XCTAssertFalse(bac.isInfinite, "结果不应为无穷大")
        XCTAssertGreaterThan(bac, 3.0, "极端饮酒量下 BAC 应 > 3%")
    }

    /// 测试酒精浓度超过 100% 的异常输入
    func test_calculateBAC_alcoholPercentOver100_allowsButCalculates() {
        let bac100 = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: 100.0, alcoholPercent: 100.0
        )
        let bac150 = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: 100.0, alcoholPercent: 150.0
        )

        XCTAssertGreaterThan(bac150, bac100, "酒精浓度 150% 应比 100% 计算结果更高")
    }

    // MARK: - 累积 BAC 边界

    /// 测试空饮酒列表的累积 BAC
    func test_calculateCumulativeBAC_emptyDrinks_returnsZero() {
        let bac = sut.calculateCumulativeBAC(
            weightKg: 70.0, isMale: true,
            drinks: [],
            metabolismRate: 0.015
        )

        XCTAssertEqual(bac, 0.0, accuracy: 0.001, "空饮酒列表应返回 0")
    }

    /// 测试完全代谢后的累积 BAC
    func test_calculateCumulativeBAC_fullyMetabolized_returnsZero() {
        // Given: 2 小时前喝的酒，代谢速率 0.015/h，已完全代谢
        let drinks: [(volumeML: Double, alcoholPercent: Double, hoursAgo: Double, isCarbonated: Bool, isEmptyStomach: Bool)] = [
            (500, 5.0, 10.0, false, false), // 10 小时前，已完全代谢
        ]

        let bac = sut.calculateCumulativeBAC(
            weightKg: 70.0, isMale: true,
            drinks: drinks,
            metabolismRate: 0.015
        )

        XCTAssertEqual(bac, 0.0, accuracy: 0.001, "完全代谢后 BAC 应为 0")
    }
}
