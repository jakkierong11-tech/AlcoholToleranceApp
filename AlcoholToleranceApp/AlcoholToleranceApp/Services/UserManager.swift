import Foundation
import SwiftData

// MARK: - 用户称号定义

/// 酒量称号结构
struct ToleranceTitle {
    let name: String
    let emoji: String
    let description: String
}

// MARK: - UserManager

/// 用户管理器 — 封装 User 模型的 CRUD 操作
/// 通过 SwiftData ModelContext 进行持久化
@MainActor
final class UserManager {
    /// SwiftData 模型上下文
    private let modelContext: ModelContext

    // MARK: - 初始化

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 查询

    /// 获取当前唯一用户（App 设计为单用户）
    /// - Returns: 第一个 User，如果不存在则返回 nil
    func fetchCurrentUser() -> User? {
        var descriptor = FetchDescriptor<User>()
        descriptor.fetchLimit = 1
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]

        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            print("[UserManager] 获取用户失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 根据 ID 获取用户
    func fetchUser(by id: UUID) -> User? {
        var descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("[UserManager] 按 ID 获取用户失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 获取所有用户（理论上只有一个）
    func fetchAllUsers() -> [User] {
        var descriptor = FetchDescriptor<User>()
        descriptor.sortBy = [SortDescriptor(\.createdAt)]

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("[UserManager] 获取所有用户失败: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 查询 + 创建（便捷方法）

    /// 获取当前用户，若不存在则自动创建默认用户
    /// - Returns: 已有用户或新创建的默认 User
    @discardableResult
    func fetchOrCreateUser() -> User {
        if let user = fetchCurrentUser() {
            return user
        }
        let user = User(
            id: UUID(),
            nickname: "酒友",
            weightKg: 65,
            isMale: true,
            birthYear: 1995,
            highestScore: 0,
            totalTests: 0,
            createdAt: Date(),
            lastActiveAt: Date()
        )
        modelContext.insert(user)
        try? modelContext.save()
        return user
    }

    // MARK: - 创建

    /// 创建新用户
    /// - Parameters:
    ///   - nickname: 昵称（默认 "酒友"）
    ///   - weightKg: 体重（公斤，默认 65）
    ///   - isMale: 性别（默认男）
    ///   - birthYear: 出生年份（默认 1995）
    /// - Returns: 新创建的 User 对象
    /// - Throws: 体重 ≤ 0 或出生年份无效时抛出 UserError
    @discardableResult
    func createUser(
        nickname: String = "酒友",
        weightKg: Double = 65.0,
        isMale: Bool = true,
        birthYear: Int = 1995
    ) throws -> User {
        // 边界验证
        guard weightKg > 0 else {
            throw UserError.invalidWeight
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        guard birthYear >= 1900 && birthYear <= currentYear else {
            throw UserError.invalidBirthYear
        }

        guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw UserError.emptyNickname
        }

        // 检查是否已有用户 — 如果存在则先提示
        if let existingUser = fetchCurrentUser() {
            throw UserError.userAlreadyExists(existing: existingUser)
        }

        let user = User(
            id: UUID(),
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            weightKg: weightKg,
            isMale: isMale,
            birthYear: birthYear,
            highestScore: 0,
            totalTests: 0,
            createdAt: Date(),
            lastActiveAt: Date()
        )

        modelContext.insert(user)
        try modelContext.save()

        return user
    }

    // MARK: - 更新

    /// 更新用户基本信息
    func updateProfile(
        user: User,
        nickname: String? = nil,
        weightKg: Double? = nil,
        isMale: Bool? = nil,
        birthYear: Int? = nil
    ) throws {
        if let nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines),
           !nickname.isEmpty {
            user.nickname = nickname
        }

        if let weightKg = weightKg {
            guard weightKg > 0 else { throw UserError.invalidWeight }
            user.weightKg = weightKg
        }

        if let isMale = isMale {
            user.isMale = isMale
        }

        if let birthYear = birthYear {
            let currentYear = Calendar.current.component(.year, from: Date())
            guard birthYear >= 1900 && birthYear <= currentYear else {
                throw UserError.invalidBirthYear
            }
            user.birthYear = birthYear
        }

        user.lastActiveAt = Date()
        try modelContext.save()
    }

    /// 更新用户酒量分数
    ///
    /// 如果 newScore 超过了 highestScore，则更新最高分并返回 true；
    /// 始终递增 totalTests。
    ///
    /// - Parameters:
    ///   - user: 目标用户
    ///   - newScore: 新的酒量评分（0-100）
    /// - Returns: 是否打破了最高分记录
    @discardableResult
    func updateUserScore(user: User, newScore: Double) -> Bool {
        guard newScore >= 0 && newScore <= 100 else {
            print("[UserManager] 分数必须在 0-100 之间，收到: \(newScore)")
            return false
        }

        user.totalTests += 1
        user.lastActiveAt = Date()

        let isNewRecord = newScore > user.highestScore
        if isNewRecord {
            user.highestScore = newScore
        }

        do {
            try modelContext.save()
        } catch {
            print("[UserManager] 更新分数失败: \(error.localizedDescription)")
        }

        return isNewRecord
    }

    // MARK: - 荣誉称号

    /// 基于分数获取酒量称号
    ///
    /// 分数区间：
    /// - < 20:  新手村
    /// - 20-39: 入门选手
    /// - 40-59: 酒场熟客
    /// - 60-79: 海量选手
    /// - 80-94: 酒神降临
    /// - ≥ 95:  千杯不醉
    ///
    /// - Parameter score: 酒量分数（0-100）
    /// - Returns: ToleranceTitle 称号对象
    nonisolated static func getUserTitle(for score: Double) -> ToleranceTitle {
        switch score {
        case ..<0:
            return ToleranceTitle(name: "新手村", emoji: "🍼", description: "刚刚上路，菜鸟一枚")
        case ..<20:
            return ToleranceTitle(name: "新手村", emoji: "🍼", description: "刚刚上路，多练练手")
        case ..<40:
            return ToleranceTitle(name: "入门选手", emoji: "🍺", description: "小有成就，继续加油")
        case ..<60:
            return ToleranceTitle(name: "酒场熟客", emoji: "🍷", description: "酒桌常客，游刃有余")
        case ..<80:
            return ToleranceTitle(name: "海量选手", emoji: "🥃", description: "千杯不倒，令人侧目")
        case ..<95:
            return ToleranceTitle(name: "酒神降临", emoji: "🍾", description: "天赋异禀，凡人之躯比肩神明")
        default:
            return ToleranceTitle(name: "千杯不醉", emoji: "👑", description: "传说级别，屹立不倒的王者")
        }
    }

    /// 获取用户当前称号（基于 highestScore）
    func getCurrentTitle(for user: User) -> ToleranceTitle {
        Self.getUserTitle(for: user.highestScore)
    }

    /// 获取用户统计数据摘要
    func getStats(for user: User) -> UserStats {
        return UserStats(
            nickname: user.nickname,
            estimatedAge: user.estimatedAge,
            weightKg: user.weightKg,
            genderLabel: user.isMale ? "男" : "女",
            highestScore: user.highestScore,
            totalTests: user.totalTests,
            title: user.title,
            titleDetail: getCurrentTitle(for: user),
            createdAt: user.createdAt,
            lastActiveAt: user.lastActiveAt
        )
    }

    // MARK: - 删除

    /// 删除用户
    func deleteUser(_ user: User) throws {
        modelContext.delete(user)
        try modelContext.save()
    }
}

// MARK: - 用户统计数据

/// 用户统计信息视图模型
struct UserStats {
    let nickname: String
    let estimatedAge: Int
    let weightKg: Double
    let genderLabel: String
    let highestScore: Double
    let totalTests: Int
    let title: String
    let titleDetail: ToleranceTitle
    let createdAt: Date
    let lastActiveAt: Date

    /// 格式化体重
    var formattedWeight: String {
        String(format: "%.1f kg", weightKg)
    }

    /// 格式化最高分
    var formattedScore: String {
        String(format: "%.0f / 100", highestScore)
    }

    /// 胜率（如果 totalTests > 0，计算超过自身最高的比例）
    var improvementRate: String {
        "\(totalTests) 次测试"
    }
}

// MARK: - 错误类型

/// 用户管理相关错误
enum UserError: LocalizedError {
    case invalidWeight
    case invalidBirthYear
    case emptyNickname
    case userAlreadyExists(existing: User)

    var errorDescription: String? {
        switch self {
        case .invalidWeight:
            return "体重必须大于 0 公斤"
        case .invalidBirthYear:
            return "出生年份无效（需在 1900-当前年份之间）"
        case .emptyNickname:
            return "昵称不能为空"
        case .userAlreadyExists(let user):
            return "已存在用户「\(user.nickname)」，本 App 仅支持单用户模式"
        }
    }
}
