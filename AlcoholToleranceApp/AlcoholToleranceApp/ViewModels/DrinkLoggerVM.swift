import Foundation
import SwiftUI
import SwiftData

// MARK: - 饮酒记录状�?
enum DrinkLoggerState { case idle, recording, done }

// MARK: - 饮酒记录 ViewModel（快速记录，不绑定完整测试流程）
/// 支持单杯/多杯快速录�?+ 实时 BAC 预估 + 标准单位换算
/// 可独立使用，也可嵌入 TestSessionVM 协作为辅助记录器
@MainActor
final class DrinkLoggerVM: ObservableObject {
    // MARK: - 当前录入状�?
    @Published var state: DrinkLoggerState = .idle
    @Published var selectedDrinkType: DrinkType = .beer
    @Published var volumeMl: Double = 500
    @Published var abv: Double = 5.0
    @Published var isCarbonated: Bool = false
    @Published var isEmptyStomach: Bool = false
    @Published var drinkCount: Int = 1

    /// 法律区域（由父视图注入，影响法定阈值）
    @Published var legalRegion: LegalRegion = .cn

    // MARK: - 预估结果

    @Published var estimatedBAC: Double?
    @Published var estimatedLevel: String?
    @Published var estimatedLevelColor: Color?
    @Published var standardDrinks: Double = 0

    // MARK: - 记录列表

    @Published private(set) var loggedDrinks: [QuickDrinkLog] = []

    private let userManager: UserManager
    private var user: User

    // MARK: - 初始�?
    init(modelContext: ModelContext) {
        self.userManager = UserManager(modelContext: modelContext)
        self.user = userManager.fetchOrCreateUser()
    }

    func refreshUser() {
        user = userManager.fetchOrCreateUser()
        refreshEstimates()
    }

    // MARK: - 类型切换

    var selectedType: DrinkType { selectedDrinkType }

    func setDrinkType(_ type: DrinkType) {
        selectedDrinkType = type
        onDrinkTypeChanged()
    }

    /// 饮品类型改变时自动补全默认值并重新预估
    func onDrinkTypeChanged() {
        volumeMl = selectedDrinkType.typicalVolumeMl
        abv = selectedDrinkType.defaultAbv
        isCarbonated = [DrinkType.beer, DrinkType.cocktail].contains(selectedDrinkType)
        refreshEstimates()
    }

    // MARK: - 预估逻辑

    /// 预估当前参数下单�?BAC
    func estimateSingleDrinkBAC() {
        guard volumeMl > 0, abv > 0, abv <= 100, user.weightKg > 0 else {
            estimatedBAC = nil
            estimatedLevel = nil
            estimatedLevelColor = nil
            return
        }
        let bac = BACCalculator.calculatePeakBAC(
            weightKg: user.weightKg,
            isMale: user.isMale,
            volumeML: volumeMl * Double(drinkCount),
            alcoholPercent: abv,
            isCarbonated: isCarbonated,
            isEmptyStomach: isEmptyStomach
        )
        estimatedBAC = bac
        let info = BACCalculator.getBACLevel(bacPercent: bac)
        estimatedLevel = info.label
        estimatedLevelColor = info.bacLevel.color
    }

    /// 计算标准饮酒单位
    func calculateStandardDrinks() {
        guard volumeMl > 0, abv > 0, abv <= 100 else {
            standardDrinks = 0
            return
        }
        standardDrinks = BACCalculator.calculateStandardDrinks(
            volumeML: volumeMl * Double(drinkCount),
            alcoholPercent: abv
        )
    }

    /// 一键刷新所有预�?    func refreshEstimates() {
        estimateSingleDrinkBAC()
        calculateStandardDrinks()
    }

    // MARK: - 日志操作

    func logDrink() {
        state = .recording
        _ = logCurrentDrink()
        state = .done
    }

    func cancelLastDrink() {
        if !loggedDrinks.isEmpty {
            loggedDrinks.removeLast()
        }
        state = .idle
    }

    /// 记录本次饮酒
    func logCurrentDrink() -> QuickDrinkLog {
        let log = QuickDrinkLog(
            drinkType: selectedDrinkType,
            volumeMl: volumeMl,
            abv: abv,
            count: drinkCount,
            isCarbonated: isCarbonated,
            isEmptyStomach: isEmptyStomach,
            estimatedBAC: estimatedBAC,
            standardDrinks: standardDrinks,
            timestamp: Date()
        )
        loggedDrinks.append(log)
        return log
    }

    /// 删除某条记录
    func removeLog(at index: Int) {
        guard index < loggedDrinks.count else { return }
        loggedDrinks.remove(at: index)
    }

    /// 清空记录
    func clearLogs() {
        loggedDrinks.removeAll()
    }

    // MARK: - 汇�?
    /// 本次记录总标准单�?    var totalStandardDrinks: Double {
        loggedDrinks.reduce(0) { $0 + $1.standardDrinks }
    }

    /// 本次记录总毫升数
    var totalVolumeMl: Double {
        loggedDrinks.reduce(0) { $0 + $1.volumeMl * Double($1.count) }
    }

    /// 本次记录总纯酒精克数
    var totalAlcoholGrams: Double {
        loggedDrinks.reduce(0) { sum, log in
            sum + (log.volumeMl * Double(log.count) * (log.abv / 100) * 0.789)
        }
    }

    // MARK: - 醒酒时间

    /// 预估醒酒所需时间（基于当前预�?BAC�?    var estimatedSoberHours: Double? {
        guard let bac = estimatedBAC, bac > 0 else { return nil }
        return BACCalculator.calculateSoberTime(currentBAC: bac)
    }

    /// 格式化醒酒时�?    var soberTimeText: String? {
        guard let hours = estimatedSoberHours else { return nil }
        return BACCalculator.formatSoberTime(hours: hours)
    }

    /// 预估安全驾驶时间�?    var safeToDriveTime: Date? {
        let limit = legalRegion.drinkDriveLimit
        guard let bac = estimatedBAC, bac >= limit else { return nil }
        let soberHours = BACCalculator.calculateSoberTime(currentBAC: bac - limit)
        return Date().addingTimeInterval(soberHours * 3600)
    }

    // MARK: - 法律阈值（委托 LegalRegion�?
    var legalLimitBAC: Double { legalRegion.drinkDriveLimit }
    var duiLimitBAC: Double { legalRegion.duiLimit }

    /// 当前预估是否超标
    var isOverLegalLimit: Bool {
        guard let bac = estimatedBAC else { return false }
        return legalRegion.isOverLimit(bac: bac)
    }

    /// 驾驶建议（区域感知）
    var drivingAdvice: String {
        guard let bac = estimatedBAC else { return "未计�? }
        return legalRegion.drivingAdvice(for: bac)
    }
}

// MARK: - 快速饮酒日志条�?
struct QuickDrinkLog: Identifiable {
    let id = UUID()
    let drinkType: DrinkType
    let volumeMl: Double
    let abv: Double
    let count: Int
    let isCarbonated: Bool
    let isEmptyStomach: Bool
    let estimatedBAC: Double?
    let standardDrinks: Double
    let timestamp: Date

    var totalVolumeMl: Double { volumeMl * Double(count) }
    var pureAlcoholMl: Double { totalVolumeMl * (abv / 100) }
    var alcoholGrams: Double { pureAlcoholMl * 0.789 }

    var emoji: String {
        switch drinkType {
        case .beer: return "🍺"
        case .wine: return "🍷"
        case .baijiu: return "🥃"
        case .whiskey: return "🥃"
        case .cocktail: return "🍸"
        case .sake: return "🍶"
        case .soju: return "🍾"
        case .custom: return "🥤"
        }
    }

    var label: String {
        "\(emoji) \(drinkType.rawValue) \(String(format: "%.0f", totalVolumeMl))ml \(String(format: "%.1f", abv))%"
    }
}
