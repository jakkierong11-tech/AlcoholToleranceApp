import XCTest
@testable import AlcoholToleranceApp

/// BACCalculator 代谢与衰减测试
/// 验证酒精代谢速率和时间衰减计算
final class BACCalculator_MetabolismTests: XCTestCase {

    var sut: BACCalculator.Type!

    override func setUp() {
        super.setUp()
        sut = BACCalculator.self
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 醒酒时间

    /// 测试代谢消除时间计算
    func test_calculateSoberTime_positiveBAC_returnsExpectedHours() {
        // Given: BAC 为 0.08%，代谢速率 0.015%/h
        let currentBAC = 0.08
        let metabolismRate = 0.015

        // When: 计算醒酒时间
        let soberTime = sut.calculateSoberTime(
            currentBAC: currentBAC,
            metabolismRate: metabolismRate
        )

        // Then: 0.08 / 0.015 ≈ 5.33 小时
        XCTAssertEqual(soberTime, 0.08 / 0.015, accuracy: 0.01, "醒酒时间计算不正确")
    }

    /// 测试 BAC 为 0 时醒酒时间为 0
    func test_calculateSoberTime_zeroBAC_returnsZero() {
        let soberTime = sut.calculateSoberTime(
            currentBAC: 0.0,
            metabolismRate: 0.015
        )

        XCTAssertEqual(soberTime, 0.0, accuracy: 0.001, "BAC 为 0 时醒酒时间应为 0")
    }

    /// 测试代谢速率为 0 时的防御性处理
    func test_calculateSoberTime_zeroMetabolismRate_returnsZero() {
        let soberTime = sut.calculateSoberTime(
            currentBAC: 0.08,
            metabolismRate: 0.0
        )

        XCTAssertEqual(soberTime, 0.0, accuracy: 0.001, "代谢速率为 0 时应返回 0")
    }

    // MARK: - BAC 时间衰减

    /// 测试 BAC 随时间线性代谢下降
    func test_calculateBACAfterTime_linearDecay_isCorrect() {
        // Given: 初始 BAC 0.08%，代谢速率 0.015%/h，经过 3 小时
        let initialBAC = 0.08
        let hoursPassed = 3.0
        let metabolismRate = 0.015

        // When:
        let currentBAC = sut.calculateBACAfterTime(
            initialBAC: initialBAC,
            hoursPassed: hoursPassed,
            metabolismRate: metabolismRate
        )

        // Then: 0.08 - 3×0.015 = 0.035%
        XCTAssertEqual(currentBAC, 0.035, accuracy: 0.001, "代谢后 BAC 不正确")
    }

    /// 测试代谢后 BAC 不会低于 0
    func test_calculateBACAfterTime_exceedsZero_clampsToZero() {
        // Given: 初始 BAC 0.02%，经过 5 小时（远超代谢所需）
        let initialBAC = 0.02
        let hoursPassed = 5.0
        let metabolismRate = 0.015

        // When:
        let currentBAC = sut.calculateBACAfterTime(
            initialBAC: initialBAC,
            hoursPassed: hoursPassed,
            metabolismRate: metabolismRate
        )

        // Then: BAC 应钳位到 0
        XCTAssertEqual(currentBAC, 0.0, accuracy: 0.001, "代谢后 BAC 不应为负数")
        XCTAssertGreaterThanOrEqual(currentBAC, 0.0, "BAC 绝不能为负数")
    }

    /// 测试时间为 0 时 BAC 不变
    func test_calculateBACAfterTime_zeroHours_returnsInitialBAC() {
        let initialBAC = 0.08

        let currentBAC = sut.calculateBACAfterTime(
            initialBAC: initialBAC,
            hoursPassed: 0.0,
            metabolismRate: 0.015
        )

        XCTAssertEqual(currentBAC, initialBAC, accuracy: 0.001, "0 小时后 BAC 应不变")
    }

    /// 测试负数时间的防御性处理
    func test_calculateBACAfterTime_negativeHours_returnsZero() {
        let currentBAC = sut.calculateBACAfterTime(
            initialBAC: 0.08,
            hoursPassed: -1.0,
            metabolismRate: 0.015
        )

        XCTAssertEqual(currentBAC, 0.0, accuracy: 0.001, "负数时间应返回 0")
    }

    /// 测试负数初始 BAC 的防御性处理
    func test_calculateBACAfterTime_negativeInitialBAC_returnsZero() {
        let currentBAC = sut.calculateBACAfterTime(
            initialBAC: -0.08,
            hoursPassed: 1.0,
            metabolismRate: 0.015
        )

        XCTAssertEqual(currentBAC, 0.0, accuracy: 0.001, "负数初始 BAC 应返回 0")
    }

    // MARK: - 碳酸与空腹影响

    /// 测试碳酸饮料加速酒精吸收（BAC 峰值更高）
    func test_calculateBAC_carbonatedDrink_hasAbsorptionMultiplier() {
        let weightKg = 70.0
        let isMale = true
        let volumeML = 300.0
        let alcoholPercent = 12.0

        let carbonatedBAC = sut.calculateBAC(
            weightKg: weightKg, isMale: isMale,
            volumeML: volumeML, alcoholPercent: alcoholPercent,
            isCarbonated: true
        )
        let nonCarbonatedBAC = sut.calculateBAC(
            weightKg: weightKg, isMale: isMale,
            volumeML: volumeML, alcoholPercent: alcoholPercent,
            isCarbonated: false
        )

        // 碳酸乘数 1.2x
        XCTAssertGreaterThan(carbonatedBAC, nonCarbonatedBAC,
            "碳酸饮料应导致更高的 BAC 峰值")
        XCTAssertEqual(carbonatedBAC / nonCarbonatedBAC, 1.2, accuracy: 0.001,
            "碳酸乘数应为 1.2")
    }

    /// 测试空腹饮酒 BAC 更高
    func test_calculateBAC_emptyStomach_hasHigherBAC() {
        let weightKg = 70.0
        let isMale = true
        let volumeML = 300.0
        let alcoholPercent = 12.0

        let emptyStomachBAC = sut.calculateBAC(
            weightKg: weightKg, isMale: isMale,
            volumeML: volumeML, alcoholPercent: alcoholPercent,
            isEmptyStomach: true
        )
        let fullStomachBAC = sut.calculateBAC(
            weightKg: weightKg, isMale: isMale,
            volumeML: volumeML, alcoholPercent: alcoholPercent,
            isEmptyStomach: false
        )

        // 空腹乘数 1.3x
        XCTAssertGreaterThan(emptyStomachBAC, fullStomachBAC,
            "空腹状态下 BAC 应更高")
        XCTAssertEqual(emptyStomachBAC / fullStomachBAC, 1.3, accuracy: 0.001,
            "空腹乘数应为 1.3")
    }

    /// 测试同时启用碳酸和空腹的叠加效果
    func test_calculateBAC_carbonatedAndEmptyStomach_combinedMultiplier() {
        let baseBAC = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: 300.0, alcoholPercent: 12.0,
            isCarbonated: false, isEmptyStomach: false
        )
        let combinedBAC = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: 300.0, alcoholPercent: 12.0,
            isCarbonated: true, isEmptyStomach: true
        )

        // 1.2 × 1.3 = 1.56
        XCTAssertEqual(combinedBAC / baseBAC, 1.56, accuracy: 0.001,
            "碳酸+空腹叠加乘数应为 1.56")
    }
}
