import Foundation
import SwiftUI
import SwiftData

// MARK: - 清醒测试类型

enum SoberTestType: String, CaseIterable {
    case reaction = "反应速度"
    case balance = "平衡测试"
    case memory = "记忆测试"
}

struct SoberTestResult {
    let score: Double
    let timeMs: Double
    let date: Date
}

// MARK: - 醒酒时间估算 ViewModel
/// 独立工具：输入当前 BAC / 饮酒量 → 输出醒酒时间、安全驾驶时间、BAC 下降曲线
@MainActor
final class SoberTestVM: ObservableObject {
    // MARK: - 输入模式

    enum InputMode: String, CaseIterable {
        case bacDirect = "直接输入 BAC"
        case drinkBased = "按饮酒量推算"

        var icon: String {
            switch self {
            case .bacDirect: return "percent"
            case .drinkBased: return "mug.fill"
            }
        }
    }

    @Published var testType: SoberTestType = .reaction
    @Published var inputMode: InputMode = .bacDirect

    /// 法律区域（由父视图注入，影响安全驾驶/酒驾阈值）
    @Published var legalRegion: LegalRegion = .cn

    // MARK: - 模式 A: 直接 BAC

    @Published var inputBAC: Double = 0.08
    @Published var metabolismRate: Double = BACCalculator.defaultMetabolismRate

    // MARK: - 模式 B: 按饮酒量

    @Published var selectedDrinkType: DrinkType = .beer
    @Published var drinkVolumeMl: Double = 500
    @Published var drinkABV: Double = 5.0
    @Published var drinkCount: Int = 3
    @Published var isCarbonated: Bool = false
    @Published var isEmptyStomach: Bool = false
    @Published var hoursSinceFirstDrink: Double = 1.0

    // MARK: - 计算结果

    @Published private(set) var currentBAC: Double = 0
    @Published private(set) var bacLevel: BACLevel = .sober
    @Published private(set) var bacLevelLabel: String = ""
    @Published private(set) var soberHours: Double = 0
    @Published private(set) var soberDate: Date = Date()
    @Published private(set) var safeDriveDate: Date = Date()
    @Published private(set) var totalAlcoholGrams: Double = 0
    @Published private(set) var standardDrinks: Double = 0
    @Published private(set) var drivingStatusText: String = ""

    // MARK: - BAC 下降曲线（每 30 分钟一个点，共 24 个点）

    @Published private(set) var bacCurvePoints: [(hours: Double, bac: Double)] = []
    @Published var lastResult: SoberTestResult?

    private let userManager: UserManager
    private var user: User

    // MARK: - 初始化

    init(modelContext: ModelContext) {
        self.userManager = UserManager(modelContext: modelContext)
        self.user = userManager.fetchOrCreateUser()
        recalculate()
    }

    func refreshUser() {
        user = userManager.fetchOrCreateUser()
        recalculate()
    }

    // MARK: - 测试操作

    func startTest() {
        recalculate()
    }

    func submitReactionTime(_ avgMs: Double) {
        lastResult = SoberTestResult(score: avgMs, timeMs: avgMs, date: Date())
    }

    func submitBalanceTest(_ score: Double) {
        lastResult = SoberTestResult(score: score, timeMs: 0, date: Date())
    }

    func submitMemoryTest(_ totalCorrect: Int, _ totalItems: Int) {
        let score = totalItems > 0 ? Double(totalCorrect) / Double(totalItems) * 100 : 0
        lastResult = SoberTestResult(score: score, timeMs: 0, date: Date())
    }

    // MARK: - 核心计算

    func recalculate() {
        switch inputMode {
        case .bacDirect:
            computeFromDirectBAC()
        case .drinkBased:
            computeFromDrinks()
        }
    }

    private func computeFromDirectBAC() {
        let bac = max(0, inputBAC)
        currentBAC = bac
        computeResults(from: bac, alcoholGrams: nil)
    }

    private func computeFromDrinks() {
        guard user.weightKg > 0, drinkVolumeMl > 0, drinkABV > 0, drinkABV <= 100 else {
            resetResults()
            return
        }

        let totalMl = drinkVolumeMl * Double(drinkCount)
        let grams = totalMl * (drinkABV / 100) * 0.789
        totalAlcoholGrams = grams
        standardDrinks = grams / 10

        // 计算峰值 BAC（不代谢时的理论峰值）
        let peakBAC = BACCalculator.calculateBACFromGrams(
            weightKg: user.weightKg,
            isMale: user.isMale,
            alcoholGrams: grams
        )

        // 应用碳酸和空腹修正（Widmark 公式的变体）
        var adjustedPeak = peakBAC
        if isCarbonated { adjustedPeak *= BACCalculator.carbonationMultiplier }
        if isEmptyStomach { adjustedPeak *= BACCalculator.emptyStomachMultiplier }

        // 减去已代谢部分
        let current = max(0, adjustedPeak - metabolismRate * max(0, hoursSinceFirstDrink))
        currentBAC = current

        computeResults(from: current, alcoholGrams: grams)
    }

    private func computeResults(from bac: Double, alcoholGrams: Double?) {
        let levelInfo = BACCalculator.getBACLevel(bacPercent: bac)
        bacLevel = levelInfo.bacLevel
        bacLevelLabel = levelInfo.label

        soberHours = BACCalculator.calculateSoberTime(currentBAC: bac, metabolismRate: metabolismRate)
        soberDate = Date().addingTimeInterval(soberHours * 3600)

        // 安全驾驶时间（BAC < 法定阈值）
        let limit = legalRegion.drinkDriveLimit
        let excessBAC = max(0, bac - limit)
        let driveWaitHours = excessBAC > 0
            ? BACCalculator.calculateSoberTime(currentBAC: excessBAC, metabolismRate: metabolismRate)
            : 0
        safeDriveDate = Date().addingTimeInterval(driveWaitHours * 3600)

        drivingStatusText = legalRegion.drivingAdvice(for: bac)

        if let grams = alcoholGrams {
            totalAlcoholGrams = grams
            standardDrinks = grams / 10
        }

        // 生成 BAC 下降曲线（每 30 分钟一个点）
        bacCurvePoints = generateBACCurve(initialBAC: bac)
    }

    private func resetResults() {
        currentBAC = 0
        bacLevel = .sober
        bacLevelLabel = "清醒"
        soberHours = 0
        soberDate = Date()
        safeDriveDate = Date()
        totalAlcoholGrams = 0
        standardDrinks = 0
        drivingStatusText = "✅ 可以驾驶"
        bacCurvePoints = []
    }

    // MARK: - BAC 曲线

    /// 生成 BAC 下降曲线（12 小时，每 30 分钟一个点）
    private func generateBACCurve(initialBAC: Double) -> [(hours: Double, bac: Double)] {
        let totalPoints = 24 // 12 小时
        let interval = 0.5  // 0.5 小时

        return (0..<totalPoints).map { i in
            let hours = Double(i) * interval
            let bac = max(0, initialBAC - metabolismRate * hours)
            return (hours: hours, bac: bac)
        }
    }

    // MARK: - 格式化输出

    var soberTimeFormatted: String {
        BACCalculator.formatSoberTime(hours: soberHours)
    }

    var safeDriveTimeFormatted: String {
        if currentBAC < legalRegion.drinkDriveLimit {
            return "现在"
        }
        let waitHours = safeDriveDate.timeIntervalSinceNow / 3600
        return BACCalculator.formatSoberTime(hours: max(0, waitHours))
    }

    var BACFormatted: String {
        BACCalculator.formatBAC(currentBAC)
    }

    /// 驾驶状态图标
    var drivingStatusIcon: String {
        let limit = legalRegion.drinkDriveLimit
        switch currentBAC {
        case ..<limit: return "✅"
        case ..<(limit * 2.5): return "⚠️"
        case ..<(limit * 4): return "🚫"
        default: return "🚨"
        }
    }

    /// 代谢率标签
    var metabolismRateLabel: String {
        String(format: "%.3f%%/小时", metabolismRate)
    }

    /// 图表需要的最大 BAC 值（用于 Y 轴缩放）
    var maxCurveBAC: Double {
        bacCurvePoints.map(\.bac).max() ?? currentBAC
    }

    // MARK: - 模式切换

    func onInputModeChanged() {
        if inputMode == .drinkBased {
            onDrinkTypeChanged()
        }
        recalculate()
    }

    func onDrinkTypeChanged() {
        drinkVolumeMl = selectedDrinkType.typicalVolumeMl
        drinkABV = selectedDrinkType.defaultAbv
        isCarbonated = [DrinkType.beer, DrinkType.cocktail].contains(selectedDrinkType)
        recalculate()
    }
}
