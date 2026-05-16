import XCTest
@testable import AlcoholToleranceApp

// MARK: - DrinkRecord Tests

/// DrinkRecord 模型测试 — 验证初始化、计算属性、输入校验
final class DrinkRecordTests: XCTestCase {

    func test_init_defaultValues() {
        let record = DrinkRecord()
        XCTAssertEqual(record.drinkType, .beer)
        XCTAssertEqual(record.volumeMl, 500.0)
        XCTAssertEqual(record.abv, 5.0)
        XCTAssertNotNil(record.id)
    }

    func test_init_customValues() {
        let record = DrinkRecord(
            drinkType: .baijiu,
            volumeMl: 100.0,
            abv: 52.0
        )
        XCTAssertEqual(record.drinkType, .baijiu)
        XCTAssertEqual(record.volumeMl, 100.0)
        XCTAssertEqual(record.abv, 52.0)
    }

    func test_init_negativeVolume_clampedTo1() {
        let record = DrinkRecord(volumeMl: -100)
        XCTAssertEqual(record.volumeMl, 1.0, "负数饮用量应被 clamp 到 1")
    }

    func test_init_zeroVolume_clampedTo1() {
        let record = DrinkRecord(volumeMl: 0)
        XCTAssertEqual(record.volumeMl, 1.0, "0 饮用量应被 clamp 到 1")
    }

    func test_init_excessiveVolume_clampedTo10000() {
        let record = DrinkRecord(volumeMl: 50000)
        XCTAssertEqual(record.volumeMl, 10000.0, "超上限应被 clamp 到 10000")
    }

    func test_init_negativeAbv_clampedTo0() {
        let record = DrinkRecord(drinkType: .custom, abv: -5)
        XCTAssertEqual(record.abv, 0.0, "负数酒精度应被 clamp 到 0")
    }

    func test_init_abvOver100_clampedTo100() {
        let record = DrinkRecord(drinkType: .custom, abv: 150)
        XCTAssertEqual(record.abv, 100.0, "超 100% 酒精度应被 clamp 到 100")
    }

    func test_pureAlcoholVolumeMl_calculation() {
        let record = DrinkRecord(drinkType: .beer, volumeMl: 500, abv: 5)
        // 500 * (5/100) = 25ml 纯酒精体积
        XCTAssertEqual(record.pureAlcoholVolumeMl, 25.0, accuracy: 0.001)
    }

    func test_alcoholGrams_calculation() {
        let record = DrinkRecord(drinkType: .beer, volumeMl: 500, abv: 5)
        // 25ml * 0.789 = 19.725g
        XCTAssertEqual(record.alcoholGrams, 19.725, accuracy: 0.001)
    }

    func test_drinkTypeRaw_roundTrip() {
        let record = DrinkRecord(drinkType: .whiskey)
        XCTAssertEqual(record.drinkTypeRaw, "威士忌")
        // 修改类型
        record.drinkType = .cocktail
        XCTAssertEqual(record.drinkTypeRaw, "鸡尾酒")
    }

    func test_allDrinkTypes_haveValidDefaults() {
        for type in DrinkType.allCases {
            let record = DrinkRecord(drinkType: type)
            XCTAssertGreaterThan(record.abv, 0, "\(type) 应有正数默认酒精度")
            XCTAssertGreaterThan(record.volumeMl, 0, "\(type) 应有正数默认饮用量")
        }
    }
}

// MARK: - User Tests

/// User 模型测试 — 验证初始化、计算属性、输入校验
final class UserTests: XCTestCase {

    func test_init_defaultValues() {
        let user = User()
        XCTAssertEqual(user.nickname, "酒友")
        XCTAssertEqual(user.weightKg, 65.0)
        XCTAssertTrue(user.isMale)
        XCTAssertEqual(user.birthYear, 1995)
        XCTAssertEqual(user.highestScore, 0)
        XCTAssertEqual(user.totalTests, 0)
    }

    func test_init_customValues() {
        let user = User(
            nickname: "老王",
            weightKg: 80.0,
            isMale: true,
            birthYear: 1985
        )
        XCTAssertEqual(user.nickname, "老王")
        XCTAssertEqual(user.weightKg, 80.0)
        XCTAssertEqual(user.birthYear, 1985)
    }

    func test_init_weightClamped_low() {
        let user = User(weightKg: 5)
        XCTAssertEqual(user.weightKg, 10.0, "体重过低应被 clamp 到 10")
    }

    func test_init_weightClamped_high() {
        let user = User(weightKg: 500)
        XCTAssertEqual(user.weightKg, 300.0, "体重过高应被 clamp 到 300")
    }

    func test_init_birthYearClamped_old() {
        let user = User(birthYear: 1800)
        XCTAssertEqual(user.birthYear, 1920, "过老出生年份应被 clamp 到 1920")
    }

    func test_init_birthYearClamped_future() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let user = User(birthYear: currentYear + 10)
        XCTAssertEqual(user.birthYear, currentYear, "未来出生年份应被 clamp 到当前年份")
    }

    func test_widmarkFactor_male() {
        let user = User(isMale: true)
        XCTAssertEqual(user.widmarkFactor, 0.68)
    }

    func test_widmarkFactor_female() {
        let user = User(isMale: false)
        XCTAssertEqual(user.widmarkFactor, 0.55)
    }

    func test_estimatedAge_calculation() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let user = User(birthYear: 1990)
        XCTAssertEqual(user.estimatedAge, currentYear - 1990)
    }

    func test_title_newUser() {
        let user = User(highestScore: 0)
        XCTAssertTrue(user.title.contains("新手村"))
    }

    func test_title_highScore() {
        let user = User(highestScore: 95)
        XCTAssertTrue(user.title.contains("千杯不醉"))
    }

    func test_negativeHighestScore_clamped() {
        let user = User(highestScore: -10)
        XCTAssertEqual(user.highestScore, 0, "负分应被 clamp 到 0")
    }

    func test_negativeTotalTests_clamped() {
        let user = User(totalTests: -5)
        XCTAssertEqual(user.totalTests, 0, "负测试次数应被 clamp 到 0")
    }
}

// MARK: - BACResult Tests

/// BACResult 模型测试 — 验证初始化、计算属性
final class BACResultTests: XCTestCase {

    func test_init_defaultValues() {
        let result = BACResult()
        XCTAssertEqual(result.bacPercent, 0)
        XCTAssertEqual(result.level, .sober)
        XCTAssertEqual(result.legalDrivingStatus, "")
    }

    func test_level_roundTrip() {
        let result = BACResult(level: .euphoric)
        XCTAssertEqual(result.level, .euphoric)
        XCTAssertEqual(result.levelRaw, "兴奋")

        result.level = .danger
        XCTAssertEqual(result.level, .danger)
        XCTAssertEqual(result.levelRaw, "危险")
    }

    func test_level_invalidRawValue_defaultsToSober() {
        let result = BACResult()
        result.levelRaw = "不存在的等级"
        XCTAssertEqual(result.level, .sober, "无效 rawValue 应回退到 sober")
    }

    func test_init_allLevels() {
        for level in BACLevel.allCases {
            let result = BACResult(level: level)
            XCTAssertEqual(result.level, level)
            XCTAssertEqual(result.levelRaw, level.rawValue)
        }
    }
}

// MARK: - DrinkSession Tests

/// DrinkSession 模型测试 — 验证初始化、关联关系
final class DrinkSessionTests: XCTestCase {

    func test_init_defaultValues() {
        let session = DrinkSession()
        XCTAssertFalse(session.isCompleted)
        XCTAssertEqual(session.totalPureAlcoholMl, 0)
        XCTAssertTrue(session.drinkRecords.isEmpty)
        XCTAssertNil(session.bacResult)
        XCTAssertNil(session.endTime)
    }

    func test_init_withDrinkRecords() {
        let record1 = DrinkRecord(drinkType: .beer, volumeMl: 500)
        let record2 = DrinkRecord(drinkType: .baijiu, volumeMl: 100)
        let session = DrinkSession(drinkRecords: [record1, record2])

        XCTAssertEqual(session.drinkRecords.count, 2)
        XCTAssertEqual(session.drinkRecords[0].drinkType, .beer)
        XCTAssertEqual(session.drinkRecords[1].drinkType, .baijiu)
    }

    func test_session_completion() {
        let session = DrinkSession()
        XCTAssertFalse(session.isCompleted)

        session.isCompleted = true
        session.endTime = Date()
        XCTAssertTrue(session.isCompleted)
        XCTAssertNotNil(session.endTime)
    }
}

// MARK: - LegalRegion Tests

/// LegalRegion 枚举测试 — 验证阈值、驾驶建议、边界条件
final class LegalRegionTests: XCTestCase {

    // MARK: - 阈值验证

    func test_drinkDriveLimits() {
        XCTAssertEqual(LegalRegion.cn.drinkDriveLimit, 0.02)
        XCTAssertEqual(LegalRegion.us.drinkDriveLimit, 0.08)
        XCTAssertEqual(LegalRegion.eu.drinkDriveLimit, 0.05)
    }

    func test_duiLimits() {
        XCTAssertEqual(LegalRegion.cn.duiLimit, 0.08)
        XCTAssertEqual(LegalRegion.us.duiLimit, 0.08)
        XCTAssertEqual(LegalRegion.eu.duiLimit, 0.08)
    }

    func test_halfLimits() {
        XCTAssertEqual(LegalRegion.cn.halfLimit, 0.01)
        XCTAssertEqual(LegalRegion.us.halfLimit, 0.04)
        XCTAssertEqual(LegalRegion.eu.halfLimit, 0.025)
    }

    // MARK: - 驾驶建议

    func test_drivingAdvice_cn_sober() {
        let advice = LegalRegion.cn.drivingAdvice(for: 0.005)
        XCTAssertTrue(advice.contains("可以驾驶"), "低于 halfLimit 应显示可以驾驶")
    }

    func test_drivingAdvice_cn_nearLimit() {
        let advice = LegalRegion.cn.drivingAdvice(for: 0.015)
        XCTAssertTrue(advice.contains("建议等待"), "接近阈值应显示警告")
    }

    func test_drivingAdvice_cn_overDrinkDrive() {
        let advice = LegalRegion.cn.drivingAdvice(for: 0.03)
        XCTAssertTrue(advice.contains("酒驾") || advice.contains("禁止"), "超过酒驾标准应禁止驾驶")
    }

    func test_drivingAdvice_cn_overDUI() {
        let advice = LegalRegion.cn.drivingAdvice(for: 0.10)
        XCTAssertTrue(advice.contains("醉驾") || advice.contains("严禁"), "超过醉驾标准应严禁驾驶")
    }

    func test_drivingAdvice_us_standard() {
        let advice = LegalRegion.us.drivingAdvice(for: 0.09)
        XCTAssertTrue(advice.contains("美国"), "应包含区域名称")
        XCTAssertTrue(advice.contains("严禁") || advice.contains("禁止"), "超过美国阈值应禁止")
    }

    func test_drivingAdvice_eu_standard() {
        let advice = LegalRegion.eu.drivingAdvice(for: 0.06)
        XCTAssertTrue(advice.contains("欧盟"), "应包含区域名称")
    }

    // MARK: - 阈值判断

    func test_isOverLimit_cn() {
        XCTAssertTrue(LegalRegion.cn.isOverLimit(bac: 0.02))
        XCTAssertTrue(LegalRegion.cn.isOverLimit(bac: 0.025))
        XCTAssertFalse(LegalRegion.cn.isOverLimit(bac: 0.019))
    }

    func test_isOverDUI_allRegions() {
        for region in LegalRegion.allCases {
            XCTAssertTrue(region.isOverDUI(bac: 0.10), "\(region) BAC 0.10 应超过 DUI 标准")
            XCTAssertFalse(region.isOverDUI(bac: 0.07), "\(region) BAC 0.07 不应超过 DUI 标准")
        }
    }

    // MARK: - 元数据

    func test_allCases_haveFlagEmoji() {
        for region in LegalRegion.allCases {
            XCTAssertFalse(region.flagEmoji.isEmpty, "\(region) 应有国旗 emoji")
        }
    }

    func test_zeroToleranceNotes() {
        XCTAssertNotNil(LegalRegion.cn.zeroToleranceNote)
        XCTAssertNotNil(LegalRegion.us.zeroToleranceNote)
        XCTAssertNotNil(LegalRegion.eu.zeroToleranceNote)
    }
}

// MARK: - BACLevel Tests

/// BACLevel 枚举测试 — 验证等级映射、属性完整性
final class BACLevelTests: XCTestCase {

    func test_allCases_haveCompleteProperties() {
        for level in BACLevel.allCases {
            XCTAssertGreaterThanOrEqual(level.levelNumber, 0)
            XCTAssertLessThan(level.levelNumber, 8)
            XCTAssertFalse(level.description.isEmpty, "\(level) 应有描述")
            XCTAssertFalse(level.drivingStatus.isEmpty, "\(level) 应有驾驶状态")
            XCTAssertFalse(level.emoji.isEmpty, "\(level) 应有 emoji")
            XCTAssertFalse(level.colorHex.isEmpty, "\(level) 应有颜色")
            XCTAssertTrue(level.colorHex.hasPrefix("#"), "颜色应为 hex 格式")
        }
    }

    func test_levelNumber_order() {
        let expectedOrder: [BACLevel] = [.sober, .mild, .euphoric, .excited, .confused, .stupor, .coma, .danger]
        for (index, level) in expectedOrder.enumerated() {
            XCTAssertEqual(level.levelNumber, index, "\(level) 的序号应为 \(index)")
        }
    }

    func test_lowerBounds_increasing() {
        var previousBound: Double = -1
        for level in BACLevel.allCases {
            XCTAssertGreaterThan(level.lowerBound, previousBound, "\(level) 的下界应递增")
            previousBound = level.lowerBound
        }
    }

    func test_rawValues_areChinese() {
        for level in BACLevel.allCases {
            XCTAssertTrue(level.rawValue.allSatisfy { $0.isASCII == false || $0.isWhitespace },
                "\(level) 的 rawValue 应为中文字符串")
        }
    }
}

// MARK: - DrinkType Tests

/// DrinkType 枚举测试 — 验证默认值、属性
final class DrinkTypeTests: XCTestCase {

    func test_allCases_haveValidDefaults() {
        for type in DrinkType.allCases {
            XCTAssertGreaterThan(type.defaultAbv, 0, "\(type) 应有正数默认酒精度")
            XCTAssertGreaterThan(type.typicalVolumeMl, 0, "\(type) 应有正数默认饮用量")
            XCTAssertFalse(type.emoji.isEmpty, "\(type) 应有 emoji")
            XCTAssertFalse(type.iconName.isEmpty, "\(type) 应有图标名")
        }
    }

    func test_baijiu_highestAbv() {
        let abvs = DrinkType.allCases.map { $0.defaultAbv }
        XCTAssertEqual(DrinkType.baijiu.defaultAbv, abvs.max(), "白酒应有最高默认酒精度")
    }

    func test_custom_fallbackValues() {
        XCTAssertEqual(DrinkType.custom.defaultAbv, 10.0)
        XCTAssertEqual(DrinkType.custom.typicalVolumeMl, 500.0)
    }

    func test_iconNames_areValidSFSymbols() {
        // SF Symbol 名称通常包含点号
        for type in DrinkType.allCases {
            XCTAssertTrue(type.iconName.contains(".") || type.iconName.contains("fill"),
                "\(type) 的图标名应符合 SF Symbol 命名规范")
        }
    }
}
