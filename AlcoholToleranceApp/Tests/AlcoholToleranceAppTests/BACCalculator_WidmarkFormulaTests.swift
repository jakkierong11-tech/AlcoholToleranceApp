import XCTest
@testable import AlcoholToleranceApp

/// BACCalculator Widmark 公式基础测试
/// 验证核心计算公式在各种标准场景下的正确性
final class BACCalculator_WidmarkFormulaTests: XCTestCase {

    var sut: BACCalculator.Type!

    override func setUp() {
        super.setUp()
        sut = BACCalculator.self
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 标准场景

    /// 测试标准男性饮酒场景的 BAC 计算
    /// 公式: BAC = (酒精克数) / (体重克数 × Widmark 因子) × 100
    func test_calculateBAC_standardMale_returnsExpectedBAC() {
        // Given: 70kg 男性，饮用 500ml 啤酒(5% 酒精度)
        let weightKg = 70.0
        let isMale = true
        let volumeML = 500.0
        let alcoholPercent = 5.0

        // When: 计算 BAC
        let bac = sut.calculateBAC(
            weightKg: weightKg,
            isMale: isMale,
            volumeML: volumeML,
            alcoholPercent: alcoholPercent
        )

        // Then: 酒精克数 = 500 × 0.05 × 0.789 = 19.725g
        //       BAC = 19.725 / (70000 × 0.68) × 100 ≈ 0.042%
        let expectedBAC = (19.725 / (70000.0 * 0.68)) * 100.0
        XCTAssertEqual(bac, expectedBAC, accuracy: 0.001, "标准男性 BAC 计算结果不正确")
    }

    /// 测试标准女性饮酒场景的 BAC 计算
    /// 女性 Widmark 因子为 0.55，相同条件下 BAC 应更高
    func test_calculateBAC_standardFemale_returnsHigherBACThanMale() {
        // Given: 55kg 女性，与男性饮用相同量的酒
        let weightKg = 55.0
        let isMale = false
        let volumeML = 500.0
        let alcoholPercent = 5.0

        // When: 计算 BAC
        let femaleBAC = sut.calculateBAC(
            weightKg: weightKg,
            isMale: isMale,
            volumeML: volumeML,
            alcoholPercent: alcoholPercent
        )

        // Then: 酒精克数相同但体重更轻 + Widmark 因子更小 → BAC 更高
        let maleBAC = sut.calculateBAC(
            weightKg: weightKg,
            isMale: true,
            volumeML: volumeML,
            alcoholPercent: alcoholPercent
        )
        XCTAssertGreaterThan(femaleBAC, maleBAC, "相同体重下女性 BAC 应高于男性")
    }

    /// 测试从已知酒精克数直接计算 BAC
    func test_calculateBACFromGrams_standardInputs_returnsExpectedBAC() {
        // Given: 70kg 男性，摄入 20g 酒精
        let weightKg = 70.0
        let isMale = true
        let alcoholGrams = 20.0

        // When:
        let bac = sut.calculateBACFromGrams(
            weightKg: weightKg,
            isMale: isMale,
            alcoholGrams: alcoholGrams
        )

        // Then: BAC = 20 / (70000 × 0.68) × 100 ≈ 0.042%
        let expectedBAC = (20.0 / (70000.0 * 0.68)) * 100.0
        XCTAssertEqual(bac, expectedBAC, accuracy: 0.001, "从克数计算 BAC 不正确")
    }

    // MARK: - 酒精类型多样性

    /// 测试啤酒（5%）的 BAC 计算
    func test_calculateBAC_beer_returnsLowBAC() {
        // Given: 70kg 男性，500ml 啤酒
        let bac = sut.calculateBAC(
            weightKg: 70, isMale: true,
            volumeML: 500, alcoholPercent: 5
        )

        // Then: BAC 应该在 0.03-0.05% 之间
        XCTAssertGreaterThan(bac, 0.03, "啤酒 BAC 不应太低")
        XCTAssertLessThan(bac, 0.06, "啤酒 BAC 不应太高")
    }

    /// 测试白酒（52%）的 BAC 计算
    func test_calculateBAC_baijiu_returnsHighBAC() {
        // Given: 70kg 男性，100ml 白酒（52%）
        let bac = sut.calculateBAC(
            weightKg: 70, isMale: true,
            volumeML: 100, alcoholPercent: 52
        )

        // Then: 酒精克数 = 100×0.52×0.789 = 41.028g
        //       BAC = 41.028/(70000×0.68)×100 ≈ 0.086%
        let expectedBAC = (41.028 / (70000 * 0.68)) * 100
        XCTAssertEqual(bac, expectedBAC, accuracy: 0.005, "白酒 BAC 计算不正确")
    }

    /// 测试红酒（12%）的 BAC 计算
    func test_calculateBAC_redWine_returnsExpectedBAC() {
        // Given: 60kg 女性，300ml 红酒
        let bac = sut.calculateBAC(
            weightKg: 60, isMale: false,
            volumeML: 300, alcoholPercent: 12
        )

        // Then: 酒精克数 = 300×0.12×0.789 = 28.404g
        //       BAC = 28.404/(60000×0.55)×100 ≈ 0.086%
        let expectedBAC = (28.404 / (60000 * 0.55)) * 100
        XCTAssertEqual(bac, expectedBAC, accuracy: 0.005, "红酒 BAC 计算不正确")
    }
}
