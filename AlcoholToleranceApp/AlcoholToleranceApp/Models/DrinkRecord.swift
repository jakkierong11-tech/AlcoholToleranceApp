import Foundation
import SwiftData

/// 饮酒类型枚举
enum DrinkType: String, Codable, CaseIterable {
    case beer = "啤酒"
    case wine = "红酒"
    case baijiu = "白酒"
    case whiskey = "威士忌"
    case cocktail = "鸡尾酒"
    case sake = "清酒"
    case soju = "烧酒"
    case custom = "自定义"

    /// 默认酒精度数 (ABV%)
    var defaultAbv: Double {
        switch self {
        case .beer:     return 5.0
        case .wine:     return 13.0
        case .baijiu:   return 52.0
        case .whiskey:  return 40.0
        case .cocktail: return 15.0
        case .sake:     return 16.0
        case .soju:     return 20.0
        case .custom:   return 10.0
        }
    }

    /// 标准饮用量（毫升）
    var typicalVolumeMl: Double {
        switch self {
        case .beer:     return 500
        case .wine:     return 150
        case .baijiu:   return 50
        case .whiskey:  return 45
        case .cocktail: return 200
        case .sake:     return 180
        case .soju:     return 360
        case .custom:   return 500
        }
    }

    /// 表情符号
    var emoji: String {
        switch self {
        case .beer:     return "🍺"
        case .wine:     return "🍷"
        case .baijiu:   return "🥃"
        case .whiskey:  return "🥃"
        case .cocktail: return "🍸"
        case .sake:     return "🍶"
        case .soju:     return "🍾"
        case .custom:   return "🥤"
        }
    }

    /// SF Symbol 图标名
    var iconName: String {
        switch self {
        case .beer:     return "mug.fill"
        case .wine:     return "wineglass.fill"
        case .baijiu:   return "flame.fill"
        case .whiskey:  return "drop.fill"
        case .cocktail: return "party.popper.fill"
        case .sake:     return "cup.and.saucer.fill"
        case .soju:     return "bubbles.and.sparkles.fill"
        case .custom:   return "questionmark.circle.fill"
        }
    }
}

/// 单次饮酒记录 — 记录喝了什么、喝了多少
@Model
final class DrinkRecord {
    /// 记录 ID
    @Attribute(.unique) var id: UUID
    /// 所属会话
    var session: DrinkSession?
    /// 饮品类型
    var drinkTypeRaw: String
    /// 饮用量（毫升）
    var volumeMl: Double
    /// 酒精度数 (ABV%)
    var abv: Double
    /// 饮用时间
    var drankAt: Date

    /// 纯酒精体积（毫升）— 不含酒精密度换算
    var pureAlcoholVolumeMl: Double {
        volumeMl * (abv / 100.0)
    }

    /// 计算出的酒精克数（酒精密度 0.789 g/ml）
    var alcoholGrams: Double {
        pureAlcoholVolumeMl * 0.789
    }

    /// 饮品类型枚举
    var drinkType: DrinkType {
        get { DrinkType(rawValue: drinkTypeRaw) ?? .custom }
        set { drinkTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        session: DrinkSession? = nil,
        drinkType: DrinkType = .beer,
        volumeMl: Double = 500.0,
        abv: Double? = nil,
        drankAt: Date = Date()
    ) {
        self.id = id
        self.session = session
        self.drinkTypeRaw = drinkType.rawValue
        // 输入校验：饮用量必须 > 0，上限 10000ml
        self.volumeMl = max(1, min(10000, volumeMl))
        let resolvedAbv = abv ?? drinkType.defaultAbv
        // 酒精度数必须在 0-100% 范围内
        self.abv = max(0, min(100, resolvedAbv))
        self.drankAt = drankAt
    }
}
