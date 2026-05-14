import Foundation

// MARK: - BAC 等级信息

/// BAC 等级描述结构体
struct BACLevelInfo {
    let level: Int
    let label: String
    let description: String
    let risk: String
    let bacLevel: BACLevel
}

/// BAC 计算引擎 — Widmark 公式
/// BAC% = (酒精克数 / (体重克数 × widmarkFactor)) × 100 - (代谢速率 × 小时)
struct BACCalculator {

    static let carbonationMultiplier = 1.2
    static let emptyStomachMultiplier = 1.3
    static let alcoholDensity = 0.789
    static let defaultMetabolismRate = 0.015

    /// 计算单次饮酒的理论峰值 BAC%（不含代谢衰减）
    /// ⚠️ 如需时间衰减后的实时 BAC，请使用 `calculateCumulativeBAC`
    @available(*, deprecated, renamed: "calculatePeakBAC")
    static func calculateBAC(
        weightKg: Double,
        isMale: Bool,
        volumeML: Double,
        alcoholPercent: Double,
        isCarbonated: Bool = false,
        isEmptyStomach: Bool = false
    ) -> Double {
        calculatePeakBAC(weightKg: weightKg, isMale: isMale, volumeML: volumeML,
            alcoholPercent: alcoholPercent, isCarbonated: isCarbonated, isEmptyStomach: isEmptyStomach)
    }

    static func calculatePeakBAC(
        weightKg: Double,
        isMale: Bool,
        volumeML: Double,
        alcoholPercent: Double,
        isCarbonated: Bool = false,
        isEmptyStomach: Bool = false
    ) -> Double {
        guard weightKg > 0, volumeML > 0, alcoholPercent > 0, alcoholPercent <= 100 else { return 0 }
        let r = isMale ? 0.68 : 0.55
        var grams = volumeML * (alcoholPercent / 100) * alcoholDensity
        if isCarbonated { grams *= carbonationMultiplier }
        if isEmptyStomach { grams *= emptyStomachMultiplier }
        return (grams / (weightKg * 1000 * r)) * 100
    }

    /// 从已知酒精克数直接计算 BAC
    static func calculateBACFromGrams(
        weightKg: Double,
        isMale: Bool,
        alcoholGrams: Double
    ) -> Double {
        guard weightKg > 0, alcoholGrams > 0 else { return 0 }
        let r = isMale ? 0.68 : 0.55
        return (alcoholGrams / (weightKg * 1000 * r)) * 100
    }

    // MARK: - 累积 BAC

    static func calculateCumulativeBAC(
        weightKg: Double,
        isMale: Bool,
        drinks: [(volumeML: Double, alcoholPercent: Double, hoursAgo: Double, isCarbonated: Bool, isEmptyStomach: Bool)],
        metabolismRate: Double = defaultMetabolismRate
    ) -> Double {
        guard weightKg > 0, metabolismRate >= 0 else { return 0 }
        var totalBAC = 0.0
        for d in drinks {
            let peak = calculatePeakBAC(weightKg: weightKg, isMale: isMale,
                volumeML: d.volumeML, alcoholPercent: d.alcoholPercent,
                isCarbonated: d.isCarbonated, isEmptyStomach: d.isEmptyStomach)
            let effectiveHours = max(0, d.hoursAgo) // 防止负数时间倒退
            totalBAC += max(0, peak - metabolismRate * effectiveHours)
        }
        return totalBAC
    }

    /// User + DrinkRecord 便捷版
    static func calculateCumulativeBAC(
        weightKg: Double,
        isMale: Bool,
        drinks: [DrinkRecord],
        metabolismRate: Double = defaultMetabolismRate,
        currentTime: Date = Date(),
        isEmptyStomach: Bool = false
    ) -> Double {
        guard weightKg > 0 else { return 0 }
        guard metabolismRate >= 0 else { return 0 }

        let mapped = drinks.map { d -> (Double, Double, Double, Bool, Bool) in
            let hours = max(0, currentTime.timeIntervalSince(d.drankAt) / 3600)
            let isCarb = [DrinkType.beer, DrinkType.cocktail].contains(d.drinkType)
            return (d.volumeMl, d.abv, hours, isCarb, isEmptyStomach)
        }
        return calculateCumulativeBAC(weightKg: weightKg, isMale: isMale, drinks: mapped, metabolismRate: metabolismRate)
    }

    // MARK: - 醒酒时间

    /// 计算经过指定小时后剩余的 BAC
    static func calculateBACAfterTime(
        initialBAC: Double,
        hoursPassed: Double,
        metabolismRate: Double = defaultMetabolismRate
    ) -> Double {
        guard initialBAC > 0, hoursPassed >= 0, metabolismRate > 0 else { return 0 }
        return max(0, initialBAC - metabolismRate * hoursPassed)
    }

    static func calculateSoberTime(currentBAC: Double, metabolismRate: Double = defaultMetabolismRate) -> Double {
        guard currentBAC > 0, metabolismRate > 0 else { return 0 }
        return currentBAC / metabolismRate
    }

    static func estimatedSoberDate(currentBAC: Double, metabolismRate: Double = defaultMetabolismRate) -> Date {
        Date().addingTimeInterval(calculateSoberTime(currentBAC: currentBAC, metabolismRate: metabolismRate) * 3600)
    }

    // MARK: - BAC 等级

    static func getBACLevel(bacPercent: Double) -> BACLevelInfo {
        let bacLevel: BACLevel
        switch bacPercent {
        case ..<0.020:  bacLevel = .sober
        case ..<0.035:  bacLevel = .mild
        case ..<0.060:  bacLevel = .euphoric
        case ..<0.100:  bacLevel = .excited
        case ..<0.200:  bacLevel = .confused
        case ..<0.300:  bacLevel = .stupor
        case ..<0.400:  bacLevel = .coma
        default:        bacLevel = .danger
        }
        return BACLevelInfo(level: bacLevel.levelNumber, label: bacLevel.rawValue,
            description: bacLevel.description, risk: bacLevel.drivingStatus, bacLevel: bacLevel)
    }

    // MARK: - 法律阈值

    static func isOverLegalLimit(bac: Double, limit: Double = 0.02) -> Bool { bac >= limit }

    /// ⚠️ 已废弃 — 硬编码中国标准，不带区域参数
    /// 请迁移到 `LegalRegion.drivingAdvice(for:)` 或 `SettingsVM.drivingAdvice(for:)`
    @available(*, deprecated, message: "Use LegalRegion.drivingAdvice(for:) or SettingsVM.drivingAdvice(for:) for region-aware advice")
    static func drivingAdvice(bac: Double) -> String {
        LegalRegion.cn.drivingAdvice(for: bac)
    }

    /// 区域感知版驾驶建议（新推荐）
    static func drivingAdvice(bac: Double, region: LegalRegion) -> String {
        region.drivingAdvice(for: bac)
    }

    // MARK: - 评分函数（设计师契约）

    /// 单次会话表现分 0-100
    /// 注意：本评分为酒量耐受评分（BAC 高 = 耐受强 = 分高），非健康评分
    static func calculateSessionScore(
        bacPercent: Double,
        totalAlcoholGrams: Double,
        weightKg: Double
    ) -> Double {
        guard weightKg > 10, bacPercent > 0 else { return 0 }
        // BAC 耐受分：越高越耐受 (上限 50)
        let bacScore = min(bacPercent / 0.4 * 50, 50)
        // 体重修正：体重越大代谢越快 (上限 25)
        let weightScore = min(weightKg / 120 * 25, 25)
        // 酒精量耐力：喝得越多身体处理能力越强 (上限 25)
        let alcoholScore = min(totalAlcoholGrams / 200 * 25, 25)
        return min(bacScore + weightScore + alcoholScore, 100)
    }

    /// 历史耐受度总分 0-100
    /// = sessionScore × 0.5 + testScore × 0.3 + experienceWeight × 0.2
    static func calculateToleranceScore(
        sessionAvg: Double? = nil,
        testAvg: Double? = nil,
        totalSessions: Int = 0
    ) -> Double {
        let s = sessionAvg ?? 0
        let t = testAvg ?? 0
        let e = min(Double(totalSessions) / 50 * 20, 20)
        // 经验分上限 20 分（totalSessions ≥ 50 时满经验）
        return s * 0.5 + t * 0.3 + e
    }

    // MARK: - 单位工具

    static func bacToMgPer100mL(_ bacPercent: Double) -> Double { bacPercent * 1000 }

    static func formatBAC(_ bacPercent: Double, style: BACFormatStyle = .percent) -> String {
        switch style {
        case .percent: return String(format: "%.3f%%", bacPercent)
        case .mgPer100mL: return String(format: "%.0f mg/100mL", bacToMgPer100mL(bacPercent))
        }
    }

    static func formatSoberTime(hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if h > 0 { return "\(h)小时\(m)分钟" }
        return "\(m)分钟"
    }

    static func calculateStandardDrinks(volumeML: Double, alcoholPercent: Double) -> Double {
        volumeML * (alcoholPercent / 100) * alcoholDensity / 10
    }

    static func getSafeDrinkingGuideline(isMale: Bool) -> (maxUnits: Double, advice: String) {
        isMale
            ? (4.0, "男性建议每日不超过 4 个标准单位（≈ 2 瓶啤酒或 200ml 白酒）")
            : (2.5, "女性建议每日不超过 2.5 个标准单位（≈ 1 瓶啤酒或 125ml 白酒）")
    }
}

enum BACFormatStyle {
    case percent
    case mgPer100mL
}
