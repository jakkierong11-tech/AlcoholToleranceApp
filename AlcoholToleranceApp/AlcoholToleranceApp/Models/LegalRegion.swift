import Foundation

// MARK: - 法律区域枚举

/// 饮酒驾驶法律区域 — 影响驾驶合法性判定阈值（域模型，独立于任何 ViewModel）
///
/// 使用方式：
/// - 纯静态函数：`LegalRegion.cn.drivingAdvice(for: bac)`
/// - 配合 SettingsVM：`settingsVM.selectedRegion.drivingAdvice(for: bac)`
/// - 搭配自定义阈值：直接读 `effectiveDrinkDriveLimit` / `effectiveDuiLimit` 自行判法
enum LegalRegion: String, Codable, CaseIterable {
    case cn = "中国大陆"
    case us = "美国"
    case eu = "欧盟"

    // MARK: - 元数据

    var flagEmoji: String {
        switch self {
        case .cn: return "🇨🇳"
        case .us: return "🇺🇸"
        case .eu: return "🇪🇺"
        }
    }

    // MARK: - 法定阈值

    /// 饮酒驾驶阈值（BAC%）
    var drinkDriveLimit: Double {
        switch self {
        case .cn: return 0.02   // 20mg/100ml
        case .us: return 0.08   // 21 岁以上大部分州
        case .eu: return 0.05   // 多数欧盟国家
        }
    }

    /// 醉酒驾驶阈值（BAC%）
    var duiLimit: Double {
        switch self {
        case .cn: return 0.08   // 80mg/100ml
        case .us: return 0.08   // 大部分州
        case .eu: return 0.08   // 加重处罚线
        }
    }

    /// 零容忍说明
    var zeroToleranceNote: String? {
        switch self {
        case .cn: return "营运车辆 / 摩托车零容忍"
        case .us: return "21 岁以下零容忍（< 0.02%）"
        case .eu: return "新手司机 / 职业司机零容忍"
        }
    }

    /// ⚠️ 半阈值（drinkDriveLimit × 0.5）— 保守安全区间上限
    /// 低于此值显示 ✅ 可以驾驶
    var halfLimit: Double { drinkDriveLimit * 0.5 }

    // MARK: - 驾驶建议（统一入口）

    /// 区域驾驶建议 — 纯函数，使用区域默认阈值
    ///
    /// 这是 **唯一的 drivingAdvice 权威实现**。
    /// `BACCalculator.drivingAdvice` 已标记废弃，请迁移到此方法。
    /// 如需自定义阈值（非区域默认），使用 SettingsVM.effectiveDrinkDriveLimit / effectiveDuiLimit 自行判法。
    func drivingAdvice(for bac: Double) -> String {
        if bac < halfLimit {
            return "✅ 可以驾驶"
        }
        if bac < drinkDriveLimit {
            return "⚠️ 接近酒驾标准（\(rawValue)），建议等待"
        }
        if bac >= duiLimit {
            return "🚨 已达醉驾标准，严禁驾驶（\(rawValue) ≥ \(String(format: "%.2f", duiLimit))%）"
        }
        return "🚫 已达酒驾标准，禁止驾驶（\(rawValue) ≥ \(String(format: "%.2f", drinkDriveLimit))%）"
    }

    /// 是否超过饮酒驾驶法定阈值
    func isOverLimit(bac: Double) -> Bool {
        bac >= drinkDriveLimit
    }

    /// 是否超过醉酒驾驶法定阈值
    func isOverDUI(bac: Double) -> Bool {
        bac >= duiLimit
    }
}
