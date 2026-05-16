import XCTest
@testable import AlcoholToleranceApp

/// BACCalculator 单元测试
/// 对齐当前实现签名：所有方法为 static，直�?BACCalculator.method() 调用

final class BACCalculatorTests: XCTestCase {

    // MARK: - Widmark 公式基础

    func test_calculateBAC_standardMale_returnsExpectedBAC() {
        let weightKg = 70.0
        let isMale = true
        let volumeML = 500.0
        let alcoholPercent = 5.0

        let bac = BACCalculator.calculateBAC(
            weightKg: weightKg, isMale: isMale,
            volumeML: volumeML, alcoholPercent: alcoholPercent
        )

        let expectedBAC = (19.725 / (70000.0 * 0.68)) * 100.0
        XCTAssertEqual(bac, expectedBAC, accuracy: 0.001)
    }

    func test_calculateBAC_standardFemale_returnsHigherBACThanMale() {
        let weightKg = 55.0
        let femaleBAC = BACCalculator.calculateBAC(
            weightKg: weightKg, isMale: false,
            volumeML: 500, alcoholPercent: 5
        )
        let maleBAC = BACCalculator.calculateBAC(
            weightKg: weightKg, isMale: true,
            volumeML: 500, alcoholPercent: 5
        )
        XCTAssertGreaterThan(femaleBAC, maleBAC, "相同体重下女�?BAC 应高于男�?)
    }

    func test_calculateBAC_multipleDrinks_accumulatesCorrectly() {
        let weightKg = 80.0
        let isMale = true
        let drinks: [(volumeML: Double, alcoholPercent: Double, hoursAgo: Double, isCarbonated: Bool, isEmptyStomach: Bool)] = [
            (300, 5.0, 2.0, false, false),
            (300, 5.0, 1.0, false, false),
            (50, 40.0, 0.5, false, false),
        ]

        let totalBAC = BACCalculator.calculateCumulativeBAC(
            weightKg: weightKg, isMale: isMale,
            drinks: drinks, metabolismRate: 0.015
        )

        let drink1BAC = (11.835 / (80000.0 * 0.68)) * 100.0 - 2.0 * 0.015
        let drink2BAC = (11.835 / (80000.0 * 0.68)) * 100.0 - 1.0 * 0.015
        let drink3BAC = (15.78 / (80000.0 * 0.68)) * 100.0 - 0.5 * 0.015
        let expected = max(0, drink1BAC) + max(0, drink2BAC) + max(0, drink3BAC)

        XCTAssertEqual(totalBAC, expected, accuracy: 0.001)
    }

    // MARK: - 醒酒时间

    func test_calculateSoberTime_positiveBAC_returnsExpectedHours() {
        let soberTime = BACCalculator.calculateSoberTime(
            currentBAC: 0.08, metabolismRate: 0.015
        )
        XCTAssertEqual(soberTime, 0.08 / 0.015, accuracy: 0.01)
    }

    func test_calculateSoberTime_zeroBAC_returnsZero() {
        let soberTime = BACCalculator.calculateSoberTime(
            currentBAC: 0.0, metabolismRate: 0.015
        )
        XCTAssertEqual(soberTime, 0.0, accuracy: 0.001)
    }

    // MARK: - BAC 代谢后时�?

    func test_calculateBACAfterTime_linearDecay_isCorrect() {
        let bac = BACCalculator.calculateBACAfterTime(
            initialBAC: 0.08, hoursPassed: 3.0, metabolismRate: 0.015
        )
        XCTAssertEqual(bac, 0.08 - 0.045, accuracy: 0.001)
    }

    func test_calculateBACAfterTime_clampsToZero() {
        let bac = BACCalculator.calculateBACAfterTime(
            initialBAC: 0.02, hoursPassed: 5.0, metabolismRate: 0.015
        )
        XCTAssertEqual(bac, 0.0, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(bac, 0.0, "BAC 不应为负�?)
    }

    func test_calculateBACAfterTime_zeroInitialBAC_returnsZero() {
        let bac = BACCalculator.calculateBACAfterTime(
            initialBAC: 0.0, hoursPassed: 5.0, metabolismRate: 0.015
        )
        XCTAssertEqual(bac, 0.0, accuracy: 0.001)
    }

    // MARK: - 边界条件

    func test_calculateBAC_zeroWeight_returnsZero() {
        let bac = BACCalculator.calculateBAC(
            weightKg: 0, isMale: true, volumeML: 500, alcoholPercent: 5
        )
        XCTAssertEqual(bac, 0.0, accuracy: 0.001)
        XCTAssertFalse(bac.isNaN)
        XCTAssertFalse(bac.isInfinite)
    }

    func test_calculateBAC_negativeWeight_returnsZero() {
        let bac = BACCalculator.calculateBAC(
            weightKg: -70, isMale: true, volumeML: 500, alcoholPercent: 5
        )
        XCTAssertEqual(bac, 0.0, accuracy: 0.001)
    }

    func test_calculateBAC_zeroVolume_returnsZero() {
        let bac = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true, volumeML: 0, alcoholPercent: 5
        )
        XCTAssertEqual(bac, 0.0, accuracy: 0.001)
    }

    func test_calculateBAC_zeroAlcoholPercent_returnsZero() {
        let bac = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true, volumeML: 500, alcoholPercent: 0
        )
        XCTAssertEqual(bac, 0.0, accuracy: 0.001)
    }

    func test_calculateBAC_negativeVolume_returnsZero() {
        let bac = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true, volumeML: -100, alcoholPercent: 5
        )
        XCTAssertEqual(bac, 0.0, accuracy: 0.001)
    }

    func test_calculateBAC_extremeWeight_returnsVeryLowBAC() {
        let bac = BACCalculator.calculateBAC(
            weightKg: 300, isMale: true, volumeML: 1000, alcoholPercent: 50
        )
        let expectedBAC = (400.0 / (300000.0 * 0.68)) * 100.0
        XCTAssertEqual(bac, expectedBAC, accuracy: 0.01)
    }

    func test_calculateBAC_extremeVolume_returnsHighBAC() {
        let bac = BACCalculator.calculateBAC(
            weightKg: 60, isMale: false, volumeML: 5000, alcoholPercent: 40
        )
        XCTAssertGreaterThan(bac, 1.0, "极大饮酒量下 BAC �?> 1%")
        XCTAssertFalse(bac.isNaN)
        XCTAssertFalse(bac.isInfinite)
    }

    // MARK: - 性别差异

    func test_calculateBAC_genderFactorRatio_isCorrect() {
        let maleBAC = BACCalculator.calculateBAC(
            weightKg: 65, isMale: true, volumeML: 300, alcoholPercent: 12
        )
        let femaleBAC = BACCalculator.calculateBAC(
            weightKg: 65, isMale: false, volumeML: 300, alcoholPercent: 12
        )
        let ratio = femaleBAC / maleBAC
        let expectedRatio = 0.68 / 0.55
        XCTAssertEqual(ratio, expectedRatio, accuracy: 0.01)
    }

    // MARK: - 酒精类型

    func test_calculateBAC_beer_returnsLowBAC() {
        let bac = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true, volumeML: 500, alcoholPercent: 5
        )
        XCTAssertGreaterThan(bac, 0.03)
        XCTAssertLessThan(bac, 0.06)
    }

    func test_calculateBAC_baijiu_returnsHighBAC() {
        let bac = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true, volumeML: 100, alcoholPercent: 52
        )
        let expectedBAC = (41.6 / (70000 * 0.68)) * 100
        XCTAssertEqual(bac, expectedBAC, accuracy: 0.005)
    }

    // MARK: - 碳酸影响

    func test_calculateBAC_carbonatedDrink_increasesPeakBAC() {
        let carbonatedBAC = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true,
            volumeML: 300, alcoholPercent: 12,
            isCarbonated: true
        )
        let nonCarbonatedBAC = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true,
            volumeML: 300, alcoholPercent: 12,
            isCarbonated: false
        )
        XCTAssertGreaterThan(carbonatedBAC, nonCarbonatedBAC, "碳酸饮料应导致更高的 BAC 峰�?)
    }

    // MARK: - 空腹影响

    func test_calculateBAC_emptyStomach_increasesPeakBAC() {
        let emptyStomachBAC = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true,
            volumeML: 300, alcoholPercent: 12,
            isEmptyStomach: true
        )
        let fullStomachBAC = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true,
            volumeML: 300, alcoholPercent: 12,
            isEmptyStomach: false
        )
        XCTAssertGreaterThan(emptyStomachBAC, fullStomachBAC, "空腹状态下 BAC 应更�?)
    }

    // MARK: - 法律阈�?

    func test_isOverLegalLimit_chinaThreshold_exceeds_returnsTrue() {
        XCTAssertTrue(BACCalculator.isOverLegalLimit(bac: 0.025, limit: 0.02))
    }

    func test_isOverLegalLimit_chinaThreshold_below_returnsFalse() {
        XCTAssertFalse(BACCalculator.isOverLegalLimit(bac: 0.018, limit: 0.02))
    }

    func test_isOverLegalLimit_USAThreshold_returnsTrue() {
        XCTAssertTrue(BACCalculator.isOverLegalLimit(bac: 0.09, limit: 0.08))
    }

    // MARK: - 评分函数

    func test_calculateSessionScore_soberBAC_returnsLowScore() {
        let score = BACCalculator.calculateSessionScore(
            bacPercent: 0.01, totalAlcoholGrams: 10, weightKg: 70
        )
        XCTAssertLessThan(score, 30, "�?BAC 应返回低耐受�?)
    }

    func test_calculateSessionScore_highBAC_returnsHighScore() {
        let score = BACCalculator.calculateSessionScore(
            bacPercent: 0.3, totalAlcoholGrams: 150, weightKg: 70
        )
        XCTAssertGreaterThan(score, 40, "�?BAC 应返回高耐受�?)
    }

    func test_calculateSessionScore_zeroBAC_returnsZero() {
        let score = BACCalculator.calculateSessionScore(
            bacPercent: 0, totalAlcoholGrams: 10, weightKg: 70
        )
        XCTAssertEqual(score, 0, accuracy: 0.001)
    }

    func test_calculateSessionScore_lowWeight_returnsZero() {
        let score = BACCalculator.calculateSessionScore(
            bacPercent: 0.1, totalAlcoholGrams: 50, weightKg: 5
        )
        XCTAssertEqual(score, 0, accuracy: 0.001)
    }

    func test_calculateToleranceScore_experienceCap_20Points() {
        let score = BACCalculator.calculateToleranceScore(
            sessionAvg: 50, testAvg: 50, totalSessions: 50
        )
        // session 50*0.5=25 + test 50*0.3=15 + experience 20 = 60
        XCTAssertEqual(score, 60, accuracy: 0.01)
    }

    func test_calculateToleranceScore_noExperience_returnsBaseOnly() {
        let score = BACCalculator.calculateToleranceScore(
            sessionAvg: 50, testAvg: 50, totalSessions: 0
        )
        XCTAssertEqual(score, 40, accuracy: 0.01) // 25 + 15 + 0
    }

    // MARK: - BAC 等级映射

    func test_getBACLevel_allBounds_returnsCorrectLevel() {
        let testCases: [(bac: Double, expectedRaw: String)] = [
            (0.000, "清醒"),
            (0.019, "清醒"),
            (0.020, "微醺"),
            (0.034, "微醺"),
            (0.035, "兴奋"),
            (0.059, "兴奋"),
            (0.060, "激�?),
            (0.099, "激�?),
            (0.100, "迷糊"),
            (0.199, "迷糊"),
            (0.200, "昏睡"),
            (0.299, "昏睡"),
            (0.300, "昏迷"),
            (0.399, "昏迷"),
            (0.400, "危险"),
        ]
        for tc in testCases {
            let info = BACCalculator.getBACLevel(bacPercent: tc.bac)
            XCTAssertEqual(info.label, tc.expectedRaw,
                "BAC \(tc.bac) 应映射到 \(tc.expectedRaw)，实�? \(info.label)")
        }
    }

    // MARK: - 工具函数

    func test_calculateBACFromGrams_standardMale_returnsExpectedBAC() {
        let bac = BACCalculator.calculateBACFromGrams(
            weightKg: 70, isMale: true, alcoholGrams: 19.725
        )
        let expected = (19.725 / (70000.0 * 0.68)) * 100.0
        XCTAssertEqual(bac, expected, accuracy: 0.001)
    }

    func test_calculateBACFromGrams_zeroGrams_returnsZero() {
        let bac = BACCalculator.calculateBACFromGrams(
            weightKg: 70, isMale: true, alcoholGrams: 0
        )
        XCTAssertEqual(bac, 0, accuracy: 0.001)
    }

    func test_formatBAC_percentStyle_returnsFormattedString() {
        let formatted = BACCalculator.formatBAC(0.045, style: .percent)
        XCTAssertEqual(formatted, "0.045%")
    }

    func test_drivingAdvice_sober_returnsSafe() {
        // BAC 0.001 < halfLimit(0.01) �?�?可以驾驶
        XCTAssertTrue(LegalRegion.cn.drivingAdvice(for: 0.001).contains("可以驾驶"))
    }

    func test_drivingAdvice_drunk_returnsForbidden() {
        XCTAssertTrue(LegalRegion.cn.drivingAdvice(for: 0.09).contains("严禁驾驶"))
    }

    // MARK: - 负时间倒退防御

    func test_calculateCumulativeBAC_negativeHoursAgo_isClamped() {
        let drinks: [(volumeML: Double, alcoholPercent: Double, hoursAgo: Double, isCarbonated: Bool, isEmptyStomach: Bool)] = [
            (300, 5.0, -1.0, false, false), // 负数时间，应�?clamp �?0
        ]
        let bac = BACCalculator.calculateCumulativeBAC(
            weightKg: 70, isMale: true, drinks: drinks
        )
        // 负数 clamp �?0，不扣除代谢 �?就是峰�?BAC
        let expected = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true, volumeML: 300, alcoholPercent: 5
        )
        XCTAssertEqual(bac, expected, accuracy: 0.001)
    }
}
