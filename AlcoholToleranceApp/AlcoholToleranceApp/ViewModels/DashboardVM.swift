import Foundation
import SwiftUI
import SwiftData

// MARK: - 首页仪表盘 ViewModel（适配总管 ProfileVM + HistoryVM）
/// 聚合用户档案、历史记录、安全指南，为 HomeView 提供单一数据入口
@MainActor
final class DashboardVM: ObservableObject {
    @Published var user: User
    @Published var recentSessions: [DrinkSession] = []
    @Published var peakBAC: Double = 0
    @Published var totalTests: Int = 0
    @Published var highestScore: Double = 0

    // BUG-004 fix: DashboardView 引用的缺失属性
    @Published var currentBAC: Double = 0
    @Published var todayDrinks: [DrinkRecord] = []

    private let userManager: UserManager
    private let sessionManager: DrinkSessionManager

    // MARK: - 初始化

    init(modelContext: ModelContext) {
        self.userManager = UserManager(modelContext: modelContext)
        self.sessionManager = DrinkSessionManager(modelContext: modelContext)
        self.user = userManager.fetchOrCreateUser()
        refresh()
    }

    /// 全量刷新仪表盘数据
    func refresh() {
        user = userManager.fetchOrCreateUser()
        recentSessions = sessionManager.fetchSessions(for: user, limit: 5)
        let results = recentSessions.compactMap(\.bacResult)
        peakBAC = results.map(\.bacPercent).max() ?? 0
        totalTests = user.totalTests
        highestScore = user.highestScore

        // 当前 BAC（最近一次会话）
        currentBAC = results.first?.bacPercent ?? 0

        // 今日饮品
        let calendar = Calendar.current
        todayDrinks = recentSessions
            .filter { calendar.isDate($0.startTime, inSameDayAs: Date()) }
            .flatMap(\.drinkRecords)
    }

    // MARK: - BAC 等级 + 评分（DashboardView 引用）

    var bacLevel: BACLevel {
        BACCalculator.getBACLevel(bacPercent: currentBAC).bacLevel
    }

    var sessionScore: Double {
        recentSessions.compactMap(\.bacResult).first?.toleranceScore ?? 0
    }

    // MARK: - 用户摘要

    var nickname: String { user.nickname }
    var genderLabel: String { user.isMale ? "男性" : "女性" }
    var weightKg: Double { user.weightKg }
    var toleranceTitle: String { user.title }
    var widmarkFactor: Double { user.widmarkFactor }

    /// 今日是否已做测试
    var hasTestedToday: Bool {
        guard let latest = recentSessions.first else { return false }
        return Calendar.current.isDate(latest.startTime, inSameDayAs: Date())
    }

    /// 最近一次已完成测试摘要
    var lastTestSummary: String? {
        guard let s = recentSessions.first(where: { $0.isCompleted }),
              let r = s.bacResult else { return nil }
        return "BAC \(String(format: "%.3f", r.bacPercent))% · \(r.level.rawValue) · 评分 \(String(format: "%.0f", r.toleranceScore))"
    }

    /// 最近测试的日期标签
    var lastTestDateLabel: String? {
        guard let s = recentSessions.first(where: { $0.isCompleted }) else { return nil }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        return f.localizedString(for: s.startTime, relativeTo: Date())
    }

    // MARK: - 安全指南

    /// 基于性别的每日安全饮酒建议
    var safeGuideline: String {
        let (maxUnits, advice) = BACCalculator.getSafeDrinkingGuideline(isMale: user.isMale)
        return advice
    }

    /// 最大标准饮酒单位
    var maxStandardUnits: Double {
        let (maxUnits, _) = BACCalculator.getSafeDrinkingGuideline(isMale: user.isMale)
        return maxUnits
    }

    /// 体重是否有效（能否开始测试）
    var canStartTest: Bool {
        user.weightKg >= 10 && user.weightKg <= 300
    }

    /// 是否有历史记录
    var hasHistory: Bool { totalTests > 0 }
}
