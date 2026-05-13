import Foundation
import SwiftData

/// 用户模型 — 存储用户基本信息与生理参数
/// 性别系数用于 Widmark 公式计算 BAC
@Model
final class User {
    /// 用户唯一标识
    @Attribute(.unique) var id: UUID
    /// 用户昵称
    var nickname: String
    /// 体重（公斤）
    var weightKg: Double
    /// 性别：true = 男性，false = 女性
    var isMale: Bool
    /// 出生年份（用于粗略年龄估算）
    var birthYear: Int
    /// 酒量等级历史最高分
    var highestScore: Double
    /// 总测试次数
    var totalTests: Int
    /// 创建日期
    var createdAt: Date
    /// 最后活跃日期
    var lastActiveAt: Date

    /// Widmark 公式中的性别系数
    /// 男性 0.68，女性 0.55
    var widmarkFactor: Double {
        isMale ? 0.68 : 0.55
    }

    /// 估算年龄
    var estimatedAge: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }

    /// 酒量称号（委托 UserManager 统一区间映射）
    var title: String {
        UserManager.getUserTitle(for: highestScore).emoji + " " + UserManager.getUserTitle(for: highestScore).name
    }

    init(
        id: UUID = UUID(),
        nickname: String = "酒友",
        weightKg: Double = 65.0,
        isMale: Bool = true,
        birthYear: Int = 1995,
        highestScore: Double = 0,
        totalTests: Int = 0,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        // 输入校验：体重必须在合理范围（10-300kg）
        self.weightKg = max(10, min(300, weightKg))
        self.isMale = isMale
        // 出生年份校验：1920 - 当前年份
        let currentYear = Calendar.current.component(.year, from: Date())
        self.birthYear = max(1920, min(currentYear, birthYear))
        self.highestScore = max(0, highestScore)
        self.totalTests = max(0, totalTests)
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
    }
}
