import Foundation
import SwiftData

/// 饮酒会话 — 一次完整的喝酒+测试过程的顶层容器
/// 包含多条 DrinkRecord 和最终 BACResult
@Model
final class DrinkSession {
    /// 会话唯一标识
    @Attribute(.unique) var id: UUID
    /// 关联用户
    var user: User?
    /// 会话开始时间
    var startTime: Date
    /// 会话结束时间
    var endTime: Date?
    /// 是否已完成
    var isCompleted: Bool
    /// 会话期间总饮酒量（毫升纯酒精）
    var totalPureAlcoholMl: Double
    /// 饮酒记录
    @Relationship(deleteRule: .cascade) var drinkRecords: [DrinkRecord]
    /// 最终的 BAC 计算结果
    var bacResult: BACResult?

    init(
        id: UUID = UUID(),
        user: User? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        isCompleted: Bool = false,
        totalPureAlcoholMl: Double = 0,
        drinkRecords: [DrinkRecord] = [],
        bacResult: BACResult? = nil
    ) {
        self.id = id
        self.user = user
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = isCompleted
        self.totalPureAlcoholMl = totalPureAlcoholMl
        self.drinkRecords = drinkRecords
        self.bacResult = bacResult
    }
}
