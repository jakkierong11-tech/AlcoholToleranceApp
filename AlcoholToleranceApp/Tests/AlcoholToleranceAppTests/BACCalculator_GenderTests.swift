import XCTest
@testable import AlcoholToleranceApp

/// BACCalculator 性别差异测试
/// 验证 Widmark 公式中性别系数（r 值）的正确应用
final class BACCalculator_GenderTests: XCTestCase {

    var sut: BACCalculator.Type!

    override func setUp() {
        super.setUp()
        sut = BACCalculator.self
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 性别系数比例

    /// 测试相同条件下女性 BAC 约为男性的 (0.68/0.55) 倍
    func test_calculateBAC_genderFactorRatio_isCorrect() {
        // Given: 相同体重、相同饮酒量
        let weightKg = 65.0
        let volumeML = 300.0
        let alcoholPercent = 12.0

        // When: 分别计算 BAC
        let maleBAC = sut.calculateBAC(
            weightKg: weightKg, isMale: true,
            volumeML: volumeML, alcoholPercent: alcoholPercent
        )
        let femaleBAC = sut.calculateBAC(
            weightKg: weightKg, isMale: false,
            volumeML: volumeML, alcoholPercent: alcoholPercent
        )

        // Then: 比例应为 0.68 / 0.55 ≈ 1.236
        let ratio = femaleBAC / maleBAC
        let expectedRatio = 0.68 / 0.55
        XCTAssertEqual(ratio, expectedRatio, accuracy: 0.01, "性别因子比例不正确")
    }

    /// 测试不同体重下性别差异的一致性
    func test_calculateBAC_differentWeights_genderDifferenceConsistent() {
        let weights = [50.0, 60.0, 70.0, 80.0, 90.0]
        let volumeML = 500.0
        let alcoholPercent = 5.0

        for weight in weights {
            let maleBAC = sut.calculateBAC(
                weightKg: weight, isMale: true,
                volumeML: volumeML, alcoholPercent: alcoholPercent
            )
            let femaleBAC = sut.calculateBAC(
                weightKg: weight, isMale: false,
                volumeML: volumeML, alcoholPercent: alcoholPercent
            )

            XCTAssertGreaterThan(femaleBAC, maleBAC,
                "体重 \(weight)kg 时女性 BAC 应高于男性")
        }
    }

    // MARK: - 极端性别场景

    /// 测试极轻体重女性的 BAC（高风险场景）
    func test_calculateBAC_lightFemale_highBAC() {
        // Given: 45kg 女性，饮用 300ml 红酒
        let bac = sut.calculateBAC(
            weightKg: 45.0, isMale: false,
            volumeML: 300.0, alcoholPercent: 12.0
        )

        // Then: 应超过中国酒驾标准 0.02%
        XCTAssertGreaterThan(bac, 0.02, "极轻体重女性饮用红酒后应超过酒驾标准")
    }

    /// 测试超重男性的 BAC（代谢优势）
    func test_calculateBAC_heavyMale_lowerBAC() {
        // Given: 120kg 男性，饮用 500ml 啤酒
        let bac = sut.calculateBAC(
            weightKg: 120.0, isMale: true,
            volumeML: 500.0, alcoholPercent: 5.0
        )

        // Then: 应低于标准体重男性的 BAC
        let standardMaleBAC = sut.calculateBAC(
            weightKg: 70.0, isMale: true,
            volumeML: 500.0, alcoholPercent: 5.0
        )

        XCTAssertLessThan(bac, standardMaleBAC, "超重男性 BAC 应低于标准体重男性")
    }
}
