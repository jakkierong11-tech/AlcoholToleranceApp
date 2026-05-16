import Foundation
import SwiftUI
import SwiftData

// MARK: - 历史记录 ViewModel（适配总管 SwiftData 持久层）

/// 历史筛选类型
enum HistoryFilter: String, CaseIterable {
    case all = "全部"
    case today = "今天"
    case week = "本周"
    case month = "本月"
    case highScore = "高分"
}

@MainActor
final class HistoryVM: ObservableObject {
    @Published var completedSessions: [DrinkSession] = []
    @Published var results: [BACResult] = []
    @Published var selectedResult: BACResult?

    // View 层兼容属性
    @Published var isLoading = false
    @Published var filter: HistoryFilter = .all

    private let sessionManager: DrinkSessionManager
    private let userManager: UserManager
    private var user: User?
    private var allSessions: [DrinkSession] = []

    init(modelContext: ModelContext) {
        self.sessionManager = DrinkSessionManager(modelContext: modelContext)
        self.userManager = UserManager(modelContext: modelContext)
        self.user = userManager.fetchCurrentUser()
        loadAll()
    }

    func setUser(_ user: User) {
        self.user = user
        loadAll()
    }

    func loadAll() {
        guard let user else { return }
        allSessions = sessionManager.fetchSessions(for: user)
        applyCurrentFilter()
    }

    /// async 包装器（View .task / .refreshable 调用）
    func loadHistory() async {
        isLoading = true
        loadAll()
        try? await Task.sleep(nanoseconds: 300_000_000) // 最小加载指示
        isLoading = false
    }

    /// 应用当前筛选条件
    func applyFilter(_ newFilter: HistoryFilter) {
        filter = newFilter
        applyCurrentFilter()
    }

    private func applyCurrentFilter() {
        let calendar = Calendar.current
        let now = Date()
        let filtered: [DrinkSession]
        switch filter {
        case .all:
            filtered = allSessions
        case .today:
            filtered = allSessions.filter { calendar.isDate($0.startTime, inSameDayAs: now) }
        case .week:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { filtered = allSessions; break }
            filtered = allSessions.filter { $0.startTime >= weekAgo }
        case .month:
            guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { filtered = allSessions; break }
            filtered = allSessions.filter { $0.startTime >= monthAgo }
        case .highScore:
            filtered = allSessions.filter { ($0.bacResult?.toleranceScore ?? 0) >= 60 }
        }
        completedSessions = filtered
        results = filtered.compactMap(\.bacResult)
    }

    /// View 层兼容别名
    var sessions: [DrinkSession] { completedSessions }

    func deleteSession(at index: Int) {
        guard index < completedSessions.count else { return }
        let session = completedSessions[index]
        try? sessionManager.deleteSession(session)
        completedSessions.remove(at: index)
    }

    /// 通过 session ID 删除（View swipeActions 调用）
    func deleteSession(_ id: UUID) {
        guard let index = completedSessions.firstIndex(where: { $0.id == id }) else { return }
        deleteSession(at: index)
    }

    var totalTests: Int {
        completedSessions.count
    }

    var peakBAC: Double {
        results.map(\.bacPercent).max() ?? 0
    }

    var highestScore: Double {
        user?.highestScore ?? 0
    }

    var toleranceTitle: String {
        user?.title ?? "🍼 新手村"
    }

    /// 按日期分组
    var groupedByDate: [(String, [(DrinkSession, BACResult)])] {
        let paired = zip(completedSessions, results).filter { (s, r) in true }
        let grouped = Dictionary(grouping: paired) { pair in
            DateFormatter.localizedString(
                from: pair.0.startTime,
                dateStyle: .medium,
                timeStyle: .none
            )
        }
        return grouped.sorted { $0.key > $1.key }
    }
}
