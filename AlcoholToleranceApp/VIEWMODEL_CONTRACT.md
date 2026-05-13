# ViewModel 接口契约

> 版本: 1.0 | 架构设计师 (@designer)
> 最后更新: 2026-05-11

## 总览

6 个 ViewModel，遵循 Clean Architecture 分层：
- **Domain**: Models (User, DrinkRecord, DrinkSession, BACResult, GameTest)
- **Data**: Services (BACCalculator, UserManager, DrinkSessionManager, GameEngine)
- **Presentation**: ViewModels → Views

---

## 1. DashboardVM

```swift
@MainActor
final class DashboardVM: ObservableObject {
    // MARK: - State
    @Published var state: DashboardState = .loading
    @Published var currentBAC: Double = 0
    @Published var bacLevel: BACLevel = .sober
    @Published var todayDrinks: [DrinkRecord] = []
    @Published var sessionScore: Double = 0

    // MARK: - Actions
    func refresh()
    func startNewSession()

    // MARK: - Dependencies
    init(
        bacCalculator: BACCalculator.Type = BACCalculator.self,
        sessionManager: DrinkSessionManager,
        userManager: UserManager
    )
}

enum DashboardState {
    case loading
    case ready
    case error(String)
}
```

## 2. DrinkLoggerVM

```swift
@MainActor
final class DrinkLoggerVM: ObservableObject {
    // MARK: - State
    @Published var state: LoggerState = .idle
    @Published var selectedType: DrinkType = .beer
    @Published var volumeMl: Double = 330
    @Published var abv: Double = 5.0
    @Published var isCarbonated: Bool = false
    @Published var isEmptyStomach: Bool = false

    // MARK: - Actions
    func logDrink()
    func cancelLastDrink()
    func setDrinkType(_ type: DrinkType)

    // MARK: - Dependencies
    init(sessionManager: DrinkSessionManager)
}

enum LoggerState {
    case idle
    case selecting
    case logging
    case done(DrinkRecord)
}

enum DrinkType: String, Codable, CaseIterable {
    case beer
    case wine
    case liquor
    case cocktail
}
```

## 3. SoberTestVM

```swift
@MainActor
final class SoberTestVM: ObservableObject {
    // MARK: - State
    @Published var state: TestState = .notStarted
    @Published var testType: SoberTestType = .reactionTime
    @Published var lastResult: Double?

    // MARK: - Actions
    func startTest()
    func submitReactionTime(_ ms: Double)
    func submitBalanceTest(_ score: Double)
    func submitMemoryTest(_ correctCount: Int, _ totalCount: Int) -> Double

    // MARK: - Dependencies
    init(gameEngine: GameEngine, userManager: UserManager)
}

enum TestState {
    case notStarted
    case inProgress
    case completed(Double)  // score 0-100
}

enum SoberTestType: String, Codable, CaseIterable {
    case reactionTime = "反应速度"
    case balance = "平衡测试"
    case memory = "记忆力"
}
```

## 4. HistoryVM

```swift
@MainActor
final class HistoryVM: ObservableObject {
    // MARK: - State
    @Published var sessions: [DrinkSession] = []
    @Published var filter: HistoryFilter = .all
    @Published var isLoading: Bool = false

    // MARK: - Actions
    func loadHistory()
    func deleteSession(_ id: UUID)
    func applyFilter(_ filter: HistoryFilter)

    // MARK: - Dependencies
    init(sessionManager: DrinkSessionManager)
}

enum HistoryFilter: String, Codable, CaseIterable {
    case all = "全部"
    case week = "本周"
    case month = "本月"
}
```

## 5. ProfileVM

```swift
@MainActor
final class ProfileVM: ObservableObject {
    // MARK: - State
    @Published var user: User
    @Published var highestScore: Double = 0
    @Published var totalSessions: Int = 0
    @Published var title: String = "🍼 新手村"

    // MARK: - Actions
    func loadProfile()
    func updateWeight(_ kg: Double)
    func updateGender(_ isMale: Bool)
    func updateNickname(_ name: String)
    func resetAllData()

    // MARK: - Dependencies
    init(userManager: UserManager)

    // NOTE: fetchOrCreateUser() 在总管接口契约中定义但 UserManager 尚未实现。
    // 临时方案：使用 fetchCurrentUser() ?? 创建默认 User
}
```

## 6. SettingsVM

```swift
@MainActor
final class SettingsVM: ObservableObject {
    // MARK: - State
    @Published var legalLimit: Double = 0.02      // 默认中国标准
    @Published var region: LegalRegion = .cn
    @Published var metabolismRate: Double = 0.015
    @Published var theme: AppTheme = .neon

    // MARK: - Actions
    func setRegion(_ region: LegalRegion)
    func setMetabolismRate(_ rate: Double)
    func resetAllData()

    // MARK: - Dependencies
    init()
}

enum LegalRegion: String, Codable, CaseIterable {
    case cn = "中国"  // 0.02% / 0.08%
    case us = "美国"  // 0.08%
    case eu = "欧洲"  // 0.05%
}

enum AppTheme: String, Codable, CaseIterable {
    case neon = "赛博朋克"
    case classic = "经典"
}
```

## 依赖关系

```
ProfileVM → UserManager
DashboardVM → BACCalculator, DrinkSessionManager, UserManager
DrinkLoggerVM → DrinkSessionManager
SoberTestVM → GameEngine, UserManager
HistoryVM → DrinkSessionManager
SettingsVM → (无外部依赖)
```

## 状态管理

当前使用 iOS 14+ 的 `ObservableObject` + `@StateObject` / `@ObservedObject`。
iOS 17+ 推荐迁移到 `@Observable` Macro，待核心功能稳定后执行。
