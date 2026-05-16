import XCTest
@testable import AlcoholToleranceApp

/// BACCalculator BAC 等级与法律阈值测试
/// 验证 BAC 等级映射和法律阈值判断
final class BACCalculator_BACLevelTests: XCTestCase {

    var sut: BACCalculator.Type!

    override func setUp() {
        super.setUp()
        sut = BACCalculator.self
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - BAC 等级边界

    /// 测试 BAC 等级边界值映射
    func test_getBACLevel_boundaryValues_returnsCorrectLevel() {
        // sober: < 0.020
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.0).bacLevel, .sober)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.019).bacLevel, .sober)

        // mild: 0.020 ..< 0.035
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.020).bacLevel, .mild)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.034).bacLevel, .mild)

        // euphoric: 0.035 ..< 0.060
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.035).bacLevel, .euphoric)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.059).bacLevel, .euphoric)

        // excited: 0.060 ..< 0.100
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.060).bacLevel, .excited)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.099).bacLevel, .excited)

        // confused: 0.100 ..< 0.200
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.100).bacLevel, .confused)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.199).bacLevel, .confused)

        // stupor: 0.200 ..< 0.300
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.200).bacLevel, .stupor)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.299).bacLevel, .stupor)

        // coma: 0.300 ..< 0.400
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.300).bacLevel, .coma)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.399).bacLevel, .coma)

        // danger: >= 0.400
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.400).bacLevel, .danger)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 0.500).bacLevel, .danger)
        XCTAssertEqual(sut.getBACLevel(bacPercent: 1.0).bacLevel, .danger)
    }

    // MARK: - 等级信息完整性

    /// 测试每个 BAC 等级的信息完整性
    func test_getBACLevel_allLevels_haveCompleteInfo() {
        let testValues: [Double] = [0.0, 0.025, 0.045, 0.080, 0.150, 0.250, 0.350, 0.500]

        for value in testValues {
            let info = sut.getBACLevel(bacPercent: value)
            XCTAssertGreaterThan(info.level, 0, "等级编号应大于 0")
            XCTAssertFalse(info.label.isEmpty, "标签不应为空")
            XCTAssertFalse(info.description.isEmpty, "描述不应为空")
            XCTAssertFalse(info.risk.isEmpty, "风险说明不应为空")
        }
    }

    // MARK: - 法律阈值

    /// 测试中国酒驾标准 (BAC ≥ 0.02%)
    func test_isOverLegalLimit_chinaThreshold_returnsTrue() {
        XCTAssertTrue(sut.isOverLegalLimit(bac: 0.025, limit: 0.02),
            "BAC 0.025% 应超过中国酒驾标准")
        XCTAssertTrue(sut.isOverLegalLimit(bac: 0.02, limit: 0.02),
            "BAC 刚好 0.02% 应判定为超标（>=）")
    }

    /// 测试低于中国酒驾标准
    func test_isOverLegalLimit_belowChinaThreshold_returnsFalse() {
        XCTAssertFalse(sut.isOverLegalLimit(bac: 0.018, limit: 0.02),
            "BAC 0.018% 不应判定为酒驾")
        XCTAssertFalse(sut.isOverLegalLimit(bac: 0.0, limit: 0.02),
            "BAC 0% 不应判定为酒驾")
    }

    /// 测试美国酒驾标准 (BAC ≥ 0.08%)
    func test_isOverLegalLimit_usaThreshold_returnsTrue() {
        XCTAssertTrue(sut.isOverLegalLimit(bac: 0.09, limit: 0.08),
            "BAC 0.09% 应超过美国酒驾标准")
    }

    /// 测试欧盟酒驾标准 (BAC ≥ 0.05%)
    func test_isOverLegalLimit_euThreshold_returnsTrue() {
        XCTAssertTrue(sut.isOverLegalLimit(bac: 0.06, limit: 0.05),
            "BAC 0.06% 应超过欧盟酒驾标准")
    }

    /// 测试零阈值（任何酒精都超标）
    func test_isOverLegalLimit_zeroThreshold_strict() {
        XCTAssertTrue(sut.isOverLegalLimit(bac: 0.001, limit: 0.0),
            "零阈值下任何 BAC 都应超标")
    }

    // MARK: - 驾驶建议

    /// 测试驾驶建议文本（对齐 LegalRegion.cn 实现）
    func test_drivingAdvice_variousBACs_returnsCorrectAdvice() {
        // BAC 0.0 < halfLimit(0.01) → ✅ 可以驾驶
        XCTAssertTrue(sut.drivingAdvice(bac: 0.0).contains("可以驾驶"))
        // BAC 0.01 = halfLimit → ⚠️ 建议等待
        XCTAssertTrue(sut.drivingAdvice(bac: 0.01).contains("建议等待"))
        // BAC 0.03 > drinkDriveLimit(0.02) → 🚫 酒驾
        XCTAssertTrue(sut.drivingAdvice(bac: 0.03).contains("酒驾"))
        // BAC 0.06 > drinkDriveLimit → 🚫 酒驾
        XCTAssertTrue(sut.drivingAdvice(bac: 0.06).contains("酒驾标准"))
        // BAC 0.10 ≥ duiLimit(0.08) → 🚨 醉驾
        XCTAssertTrue(sut.drivingAdvice(bac: 0.10).contains("醉驾"))
    }

    // MARK: - 评分函数

    /// 测试 calculateSessionScore — BAC 越高分数越高（耐受度越强）
    func test_calculateSessionScore_higherBACHigherScore() {
        let score1 = sut.calculateSessionScore(
            bacPercent: 0.02, totalAlcoholGrams: 20, weightKg: 70
        )
        let score2 = sut.calculateSessionScore(
            bacPercent: 0.20, totalAlcoholGrams: 20, weightKg: 70
        )

        XCTAssertGreaterThan(score2, score1,
            "BAC 越高，sessionScore 应越高（耐受度越强）")
    }

    /// 测试 calculateSessionScore 边界 — 极低体重
    func test_calculateSessionScore_lowWeight_returnsZero() {
        let score = sut.calculateSessionScore(
            bacPercent: 0.1, totalAlcoholGrams: 50, weightKg: 5.0
        )
        XCTAssertEqual(score, 0.0, "体重过低时应返回 0")
    }

    /// 测试 calculateSessionScore 边界 — BAC 为 0
    func test_calculateSessionScore_zeroBAC_returnsZero() {
        let score = sut.calculateSessionScore(
            bacPercent: 0.0, totalAlcoholGrams: 50, weightKg: 70.0
        )
        XCTAssertEqual(score, 0.0, "BAC 为 0 时应返回 0")
    }

    /// 测试 calculateSessionScore 爆表情况
    func test_calculateSessionScore_extremeValues_capsAt100() {
        let score = sut.calculateSessionScore(
            bacPercent: 0.001,  // 极低 BAC
            totalAlcoholGrams: 1000.0,
            weightKg: 200.0
        )
        XCTAssertEqual(score, 100.0, accuracy: 0.01, "SessionScore 应被钳制在 100")
    }

    /// 测试 calculateToleranceScore 基础计算
    func test_calculateToleranceScore_standardInputs_returnsExpectedScore() {
        // Given: sessionAvg=60, testAvg=70, totalSessions=30
        let sessionAvg = 60.0
        let testAvg = 70.0
        let totalSessions = 30

        let score = sut.calculateToleranceScore(
            sessionAvg: sessionAvg,
            testAvg: testAvg,
            totalSessions: totalSessions
        )

        // Then: s*0.5 + t*0.3 + e*0.2
        //       e = min(30/50*20, 20) = 12
        //       score = 60*0.5 + 70*0.3 + 12 = 30 + 21 + 12 = 63
        let expectedE = min(Double(totalSessions) / 50 * 20, 20)
        let expected = sessionAvg * 0.5 + testAvg * 0.3 + expectedE

        XCTAssertEqual(score, expected, accuracy: 0.01, "ToleranceScore 计算不正确")
    }

    /// 测试 calculateToleranceScore 无历史数据
    func test_calculateToleranceScore_noHistory_returnsZero() {
        let score = sut.calculateToleranceScore(
            sessionAvg: nil,
            testAvg: nil,
            totalSessions: 0
        )
        XCTAssertEqual(score, 0.0, accuracy: 0.01, "无历史数据时应返回 0")
    }

    /// 测试 calculateToleranceScore 经验分上限 20
    func test_calculateToleranceScore_maxExperience_capsAt20() {
        let score = sut.calculateToleranceScore(
            sessionAvg: 50.0,
            testAvg: 50.0,
            totalSessions: 100
        )

        // e = min(100/50*20, 20) = 20
        let expectedE = 20.0
        let expected = 50.0 * 0.5 + 50.0 * 0.3 + expectedE
        XCTAssertEqual(score, expected, accuracy: 0.01, "经验分应被钳制在 20")
    }

    // MARK: - 工具函数

    /// 测试 BAC 格式化
    func test_formatBAC_percentStyle_returnsFormattedString() {
        XCTAssertEqual(sut.formatBAC(0.082, style: .percent), "0.082%")
        XCTAssertEqual(sut.formatBAC(0.0, style: .percent), "0.000%")
    }

    /// 测试 mg/100mL 转换
    func test_bacToMgPer100mL_conversion_isCorrect() {
        XCTAssertEqual(sut.bacToMgPer100mL(0.02), 20.0, accuracy: 0.001)
        XCTAssertEqual(sut.bacToMgPer100mL(0.08), 80.0, accuracy: 0.001)
    }

    /// 测试醒酒时间格式化
    func test_formatSoberTime_hoursAndMinutes_returnsCorrectString() {
        XCTAssertEqual(sut.formatSoberTime(hours: 5.5), "5小时30分钟")
        XCTAssertEqual(sut.formatSoberTime(hours: 0.5), "30分钟")
        XCTAssertEqual(sut.formatSoberTime(hours: 2.0), "2小时0分钟")
    }

    /// 测试标准饮酒单位计算
    func test_calculateStandardDrinks_beer_returnsExpectedUnits() {
        // 500ml 啤酒 5%
        let units = sut.calculateStandardDrinks(volumeML: 500, alcoholPercent: 5)
        // 500 * 0.05 * 0.789 / 10 = 1.9725
        XCTAssertEqual(units, 1.9725, accuracy: 0.001)
    }
}
