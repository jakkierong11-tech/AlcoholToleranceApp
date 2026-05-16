import Foundation
import SwiftData

/// BAC（血液酒精浓度）计算结果
/// 核心计算基于 Widmark 公式
@Model
final class BACResult {
    /// 结果 ID
    @Attribute(.unique) var id: UUID
    /// 所属会话
    var session: DrinkSession?
    /// 计算时间
    var calculatedAt: Date
    /// BAC 百分比值（如 0.08 表示 0.08%）
    var bacPercent: Double
    /// 总酒精克数
    var totalAlcoholGrams: Double
    /// 体重（公斤）
    var weightKg: Double
    /// Widmark 性别系数
    var widmarkFactor: Double
    /// 从开始饮酒到现在的总时间（小时）
    var elapsedHours: Double
    /// 代谢掉的酒精克数
    var metabolizedGrams: Double
    /// 酒量评分（0-100）
    var toleranceScore: Double
    /// BAC 等级
    var levelRaw: String
    /// 法律驾驶状态
    var legalDrivingStatus: String
    /// 身体反应描述
    var physicalEffects: String

    /// BAC 等级枚举 — @Transient 明确告知 SwiftData 不观察/不持久化
    @Transient var level: BACLevel {
        get { BACLevel(rawValue: levelRaw) ?? .sober }
        set { levelRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        session: DrinkSession? = nil,
        calculatedAt: Date = Date(),
        bacPercent: Double = 0,
        totalAlcoholGrams: Double = 0,
        weightKg: Double = 65.0,
        widmarkFactor: Double = 0.68,
        elapsedHours: Double = 0,
        metabolizedGrams: Double = 0,
        toleranceScore: Double = 0,
        level: BACLevel = .sober,
        legalDrivingStatus: String = "",
        physicalEffects: String = ""
    ) {
        self.id = id
        self.session = session
        self.calculatedAt = calculatedAt
        self.bacPercent = bacPercent
        self.totalAlcoholGrams = totalAlcoholGrams
        self.weightKg = weightKg
        self.widmarkFactor = widmarkFactor
        self.elapsedHours = elapsedHours
        self.metabolizedGrams = metabolizedGrams
        self.toleranceScore = toleranceScore
        self.levelRaw = level.rawValue
        self.legalDrivingStatus = legalDrivingStatus
        self.physicalEffects = physicalEffects
    }
}

/// BAC 等级枚举
enum BACLevel: String, Codable, CaseIterable {
    case sober          = "清醒"
    case mild           = "微醺"
    case euphoric       = "兴奋"
    case excited        = "激动"
    case confused       = "迷糊"
    case stupor         = "昏睡"
    case coma           = "昏迷"
    case danger         = "危险"

    /// 等级数值 0-7
    var levelNumber: Int {
        switch self {
        case .sober:    return 0
        case .mild:     return 1
        case .euphoric: return 2
        case .excited:  return 3
        case .confused: return 4
        case .stupor:   return 5
        case .coma:     return 6
        case .danger:   return 7
        }
    }

    /// BAC 百分比范围下限
    var lowerBound: Double {
        switch self {
        case .sober:    return 0.000
        case .mild:     return 0.020
        case .euphoric: return 0.035
        case .excited:  return 0.060
        case .confused: return 0.100
        case .stupor:   return 0.200
        case .coma:     return 0.300
        case .danger:   return 0.400
        }
    }

    /// 中文描述
    var description: String {
        switch self {
        case .sober:    return "完全清醒，无酒精影响"
        case .mild:     return "轻微放松，话变多了"
        case .euphoric: return "愉悦兴奋，自信满满"
        case .excited:  return "情绪激动，反应略慢"
        case .confused: return "头昏脑胀，走路不稳"
        case .stupor:   return "严重迷糊，可能断片"
        case .coma:     return "失去意识，非常危险"
        case .danger:   return "生命危险，立即就医！"
        }
    }

    /// 法律驾驶状态
    var drivingStatus: String {
        switch self {
        case .sober:    return "✅ 可以驾驶"
        case .mild:     return "⚠️ 已触及饮酒驾驶标准（中国 ≥20mg/100ml）"
        case .euphoric: return "🚫 酒驾（中国 ≥0.02%）"
        case .excited:  return "🚫 酒驾，超标严重"
        case .confused: return "🚨 醉驾标准（中国 ≥0.08%）"
        case .stupor:   return "🚨 严重醉驾"
        case .coma:     return "🏥 需要医疗救助"
        case .danger:   return "☠️ 极度危险！"
        }
    }

    /// 表情符号
    var emoji: String {
        switch self {
        case .sober:    return "😇"
        case .mild:     return "😊"
        case .euphoric: return "🥳"
        case .excited:  return "🤪"
        case .confused: return "🥴"
        case .stupor:   return "😵"
        case .coma:     return "💀"
        case .danger:   return "☠️"
        }
    }

    /// 颜色（十六进制，赛博朋克霓虹色系）
    var colorHex: String {
        switch self {
        case .sober:    return "#10B981"
        case .mild:     return "#06B6D4"
        case .euphoric: return "#8B5CF6"
        case .excited:  return "#F59E0B"
        case .confused: return "#EC4899"
        case .stupor:   return "#F472B6"
        case .coma:     return "#EF4444"
        case .danger:   return "#DC2626"
        }
    }
}
