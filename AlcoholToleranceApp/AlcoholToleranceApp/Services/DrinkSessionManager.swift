import Foundation
import SwiftData

// MARK: - DrinkSessionManager

/// 饮酒会话管理�?///
/// 管理一次完整饮�?测试的生命周期：
/// 1. startSession �?创建会话
/// 2. addDrink �?逐杯记录
/// 3. endSession �?关闭会话并生�?BAC 结果
@MainActor
final class DrinkSessionManager {
    private let modelContext: ModelContext
    private let bacCalculator = BACCalculator.self

    // MARK: - 初始�?
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 会话管理

    /// 开启新的饮酒会�?    /// - Parameters:
    ///   - user: 关联的用�?    ///   - isEmptyStomach: 是否空腹（影响吸收速率�?    /// - Returns: 新创建的 DrinkSession
    @discardableResult
    func startSession(user: User?, isEmptyStomach: Bool = false) -> DrinkSession {
        let session = DrinkSession(
            id: UUID(),
            user: user,
            startTime: Date(),
            endTime: nil,
            isCompleted: false,
            totalPureAlcoholMl: 0,
            drinkRecords: [],
            bacResult: nil
        )

        modelContext.insert(session)
        try? modelContext.save()

        return session
    }

    /// 添加一杯酒到当前会�?    ///
    /// 自动计算和累加纯酒精总量�?    ///
    /// - Parameters:
    ///   - session: 目标会话
    ///   - drinkType: 酒类�?beer / .wine / .baijiu / …）
    ///   - volumeML: 饮用量（毫升�?    ///   - abv: 酒精度数（百分比，传 nil 则使用该酒类默认度数�?    ///   - drankAt: 饮用时间（默�?now�?    /// - Returns: 新增�?DrinkRecord
    /// - Throws: SessionError.sessionClosed 如果会话已关�?    @discardableResult
    func addDrink(
        to session: DrinkSession,
        type drinkType: DrinkType,
        volumeML: Double,
        abv: Double? = nil,
        drankAt: Date = Date()
    ) throws -> DrinkRecord {
        guard !session.isCompleted else {
            throw SessionError.sessionClosed
        }
        guard volumeML > 0 else {
            throw SessionError.invalidVolume
        }

        let effectiveAbv = abv ?? drinkType.defaultAbv
        guard effectiveAbv > 0 && effectiveAbv <= 100 else {
            throw SessionError.invalidAlcoholPercent
        }

        let record = DrinkRecord(
            id: UUID(),
            session: session,
            drinkType: drinkType,
            volumeML: volumeML,
            abv: effectiveAbv,
            drankAt: drankAt
        )

        // 累加纯酒精量
        session.totalPureAlcoholMl += record.pureAlcoholVolumeMl
        session.drinkRecords.append(record)

        modelContext.insert(record)
        try modelContext.save()

        return record
    }

    /// 批量添加多杯酒（用于快速输入）
    /// - Parameters:
    ///   - session: 目标会话
    ///   - entries: [(drinkType, volumeML, abv?)] 数组
    /// - Returns: 添加�?DrinkRecord 数组
    @discardableResult
    func addDrinks(
        to session: DrinkSession,
        entries: [(type: DrinkType, volumeML: Double, abv: Double?)]
    ) throws -> [DrinkRecord] {
        var records: [DrinkRecord] = []

        for entry in entries {
            let record = try addDrink(
                to: session,
                type: entry.type,
                volumeML: entry.volumeML,
                abv: entry.abv
            )
            records.append(record)
        }

        return records
    }

    /// 删除某杯酒记录并重新计算总量
    func removeDrink(_ record: DrinkRecord, from session: DrinkSession) throws {
        guard !session.isCompleted else {
            throw SessionError.sessionClosed
        }
        guard let index = session.drinkRecords.firstIndex(where: { $0.id == record.id }) else {
            throw SessionError.recordNotFound
        }

        session.drinkRecords.remove(at: index)
        session.totalPureAlcoholMl = session.drinkRecords.reduce(0) { $0 + $1.pureAlcoholVolumeMl }

        modelContext.delete(record)
        try modelContext.save()
    }

    // MARK: - 会话结算

    /// 结束会话并生�?BAC 结果
    ///
    /// 使用 Widmark 公式计算累积 BAC，同时计算：
    /// - 酒量评分（基�?BAC + 饮酒�?+ 体重综合评估�?    /// - BAC 等级
    /// - 驾驶法律状�?    ///
    /// - Parameters:
    ///   - session: 要结束的会话
    ///   - metabolismRate: 代谢速率（默�?0.015%/小时�?    ///   - isEmptyStomach: 是否空腹
    /// - Returns: 生成�?BACResult
    /// - Throws: SessionError 相关错误
    @discardableResult
    func endSession(
        _ session: DrinkSession,
        metabolismRate: Double = BACCalculator.defaultMetabolismRate,
        isEmptyStomach: Bool = false
    ) throws -> BACResult {
        guard !session.isCompleted else {
            throw SessionError.alreadyEnded
        }
        guard !session.drinkRecords.isEmpty else {
            throw SessionError.noDrinksRecorded
        }
        guard let user = session.user else {
            throw SessionError.noUserAssociated
        }
        guard user.weightKg > 0 else {
            throw SessionError.invalidUserWeight
        }

        let now = Date()

        // 计算累积 BAC
        let bacPercent = BACCalculator.calculateCumulativeBAC(
            weightKg: user.weightKg,
            isMale: user.isMale,
            drinks: session.drinkRecords,
            metabolismRate: metabolismRate,
            currentTime: now,
            isEmptyStomach: isEmptyStomach
        )

        // 总酒精克�?        let totalAlcoholGrams = session.drinkRecords.reduce(0.0) { $0 + $1.alcoholGrams }

        // 经过时间
        guard let firstDrinkTime = session.drinkRecords.map(\.drankAt).min() else {
            throw SessionError.noDrinksRecorded
        }
        let elapsedHours = now.timeIntervalSince(firstDrinkTime) / 3600.0

        // 代谢量：metabolizedGrams = metabolismRate(%/h) × elapsedHours × weightKg × 1000 × widmarkFactor / 100
        let metabolizedGrams = metabolismRate * elapsedHours * user.weightKg * 1000 * user.widmarkFactor / 100.0

        // 酒量评分：统一使用 BACCalculator.calculateSessionScore（设计师契约公式�?        let toleranceScore = BACCalculator.calculateSessionScore(
            bacPercent: bacPercent,
            totalAlcoholGrams: totalAlcoholGrams,
            weightKg: user.weightKg
        )

        // 获取等级信息
        let levelInfo = BACCalculator.getBACLevel(bacPercent: bacPercent)

        // 驾驶建议
        let drivingStatus = BACCalculator.drivingAdvice(bacPercent: bacPercent)

        let result = BACResult(
            id: UUID(),
            session: session,
            calculatedAt: now,
            bacPercent: bacPercent,
            totalAlcoholGrams: totalAlcoholGrams,
            weightKg: user.weightKg,
            widmarkFactor: user.widmarkFactor,
            elapsedHours: elapsedHours,
            metabolizedGrams: max(0, metabolizedGrams),
            toleranceScore: toleranceScore,
            level: levelInfo.bacLevel,
            legalDrivingStatus: drivingStatus,
            physicalEffects: levelInfo.description
        )

        // 更新会话
        session.endTime = now
        session.isCompleted = true
        session.bacResult = result

        modelContext.insert(result)
        try modelContext.save()

        return result
    }

    // MARK: - 查询

    /// 获取用户的所有会话（按时间倒序�?    func fetchSessions(for user: User, limit: Int = 20) -> [DrinkSession] {
        let userId = user.id
        var descriptor = FetchDescriptor<DrinkSession>(
            predicate: #Predicate { $0.user?.id == userId }
        )
        descriptor.sortBy = [SortDescriptor(\.startTime, order: .reverse)]
        descriptor.fetchLimit = limit

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("[DrinkSessionManager] 获取会话失败: \(error.localizedDescription)")
            return []
        }
    }

    /// 获取进行中的会话（未结束的）
    func fetchActiveSession(for user: User) -> DrinkSession? {
        let userId = user.id
        var descriptor = FetchDescriptor<DrinkSession>(
            predicate: #Predicate { $0.user?.id == userId && $0.isCompleted == false }
        )
        descriptor.sortBy = [SortDescriptor(\.startTime, order: .reverse)]
        descriptor.fetchLimit = 1

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("[DrinkSessionManager] 获取进行中会话失�? \(error.localizedDescription)")
            return nil
        }
    }

    /// 删除会话及其所有记�?    func deleteSession(_ session: DrinkSession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    // MARK: - 辅助计算

    /// 实时计算当前会话�?BAC（不保存�?    /// - Parameters:
    ///   - session: 当前会话
    ///   - metabolismRate: 代谢速率
    /// - Returns: 当前累积 BAC%
    func calculateLiveBAC(
        for session: DrinkSession,
        metabolismRate: Double = BACCalculator.defaultMetabolismRate
    ) -> Double? {
        guard let user = session.user, user.weightKg > 0 else { return nil }
        guard !session.drinkRecords.isEmpty else { return 0 }

        return BACCalculator.calculateCumulativeBAC(
            weightKg: user.weightKg,
            isMale: user.isMale,
            drinks: session.drinkRecords,
            metabolismRate: metabolismRate
        )
    }

    /// 获取会话摘要（文字版�?    func getSessionSummary(_ session: DrinkSession) -> String {
        guard session.isCompleted, let result = session.bacResult else {
            let drinkCount = session.drinkRecords.count
            return "🔄 进行中的会话 �?已记�?\(drinkCount) 杯酒"
        }

        let minutes = Int((session.endTime?.timeIntervalSince(session.startTime) ?? 0) / 60)
        let levelInfo = BACCalculator.getBACLevel(bacPercent: result.bacPercent)

        return """
        📋 会话摘要
        🕐 时长: \(minutes) 分钟
        🍺 杯数: \(session.drinkRecords.count)
        🧪 BAC: \(BACCalculator.formatBAC(result.bacPercent))
        📊 等级: \(levelInfo.label)
        🍷 评分: \(String(format: "%.0f", result.toleranceScore)) / 100
        \(result.legalDrivingStatus)
        """
    }
}

// MARK: - 错误类型

/// 会话管理错误
enum SessionError: LocalizedError {
    case sessionClosed
    case alreadyEnded
    case noDrinksRecorded
    case noUserAssociated
    case invalidUserWeight
    case invalidVolume
    case invalidAlcoholPercent
    case recordNotFound

    var errorDescription: String? {
        switch self {
        case .sessionClosed:
            return "会话已关闭，无法添加饮品"
        case .alreadyEnded:
            return "会话已经结束"
        case .noDrinksRecorded:
            return "没有记录任何饮酒，无法结�?
        case .noUserAssociated:
            return "会话未关联用�?
        case .invalidUserWeight:
            return "用户体重无效"
        case .invalidVolume:
            return "饮用量必须大�?0 毫升"
        case .invalidAlcoholPercent:
            return "酒精度数需�?0-100 之间"
        case .recordNotFound:
            return "找不到指定的饮酒记录"
        }
    }
}
