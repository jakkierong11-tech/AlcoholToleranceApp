import Foundation
import SwiftUI

// MARK: - 应用设置 ViewModel

/// 用户偏好设置 — 区域、代谢率、通知、BAC 告警阈值等
/// 所有持久化通过 UserDefaults，初始化时加载
/// 注意: init 期间 isInitializing = true 避免每个 @Published 的 didSet 重复落盘
@MainActor
final class SettingsVM: ObservableObject {

    // MARK: - 区域设置

    @Published var selectedRegion: LegalRegion = .cn {
        didSet { persist(Keys.legalRegion, selectedRegion.rawValue) }
    }

    var region: LegalRegion { selectedRegion }

    func setRegion(_ region: LegalRegion) {
        selectedRegion = region
    }

    // MARK: - 代谢设置

    /// 自定义代谢速率（%/小时，范围 0.005–0.030）
    @Published var metabolismRate: Double = BACCalculator.defaultMetabolismRate {
        didSet {
            metabolismRate = validatedMetabolismRate
            persist(Keys.metabolismRate, metabolismRate)
        }
    }

    func setMetabolismRate(_ rate: Double) {
        metabolismRate = rate
    }

    var validatedMetabolismRate: Double {
        max(0.005, min(0.030, metabolismRate))
    }

    // MARK: - 酒精吸收修正

    @Published var enableCarbonationBoost: Bool = true {
        didSet { persist(Keys.carbonationBoost, enableCarbonationBoost) }
    }

    @Published var enableEmptyStomachBoost: Bool = true {
        didSet { persist(Keys.emptyStomachBoost, enableEmptyStomachBoost) }
    }

    // MARK: - BAC 告警阈值（nil = 跟随区域默认）

    @Published var customDrinkDriveLimit: Double? {
        didSet {
            if let v = customDrinkDriveLimit {
                persist(Keys.customDrinkDriveLimit, v)
            } else {
                persistRemove(Keys.customDrinkDriveLimit)
            }
        }
    }

    @Published var customDuiLimit: Double? {
        didSet {
            if let v = customDuiLimit {
                persist(Keys.customDuiLimit, v)
            } else {
                persistRemove(Keys.customDuiLimit)
            }
        }
    }

    // MARK: - 通知设置

    @Published var enableTestReminder: Bool = false {
        didSet { persist(Keys.testReminder, enableTestReminder) }
    }

    @Published var reminderHour: Int = 20 {
        didSet {
            reminderHour = validatedReminderHour
            persist(Keys.reminderHour, reminderHour)
        }
    }

    var validatedReminderHour: Int {
        max(0, min(23, reminderHour))
    }

    @Published var enableSoberAlert: Bool = true {
        didSet { persist(Keys.soberAlert, enableSoberAlert) }
    }

    // MARK: - 显示设置

    @Published var useMetricUnits: Bool = true {
        didSet { persist(Keys.metricUnits, useMetricUnits) }
    }

    @Published var showBACCurve: Bool = true {
        didSet { persist(Keys.bacCurve, showBACCurve) }
    }

    @Published var theme: AppTheme = .neon

    func resetAllData() {
        resetToDefaults()
    }

    // MARK: - 私有

    private let defaults = UserDefaults.standard
    private var isInitializing = true

    private func persist(_ key: String, _ value: Any) {
        guard !isInitializing else { return }
        defaults.set(value, forKey: key)
    }

    private func persistRemove(_ key: String) {
        guard !isInitializing else { return }
        defaults.removeObject(forKey: key)
    }

    enum Keys {
        static let legalRegion = "legalRegion"
        static let metabolismRate = "metabolismRate"
        static let carbonationBoost = "enableCarbonationBoost"
        static let emptyStomachBoost = "enableEmptyStomachBoost"
        static let customDrinkDriveLimit = "customDrinkDriveLimit"
        static let customDuiLimit = "customDuiLimit"
        static let testReminder = "enableTestReminder"
        static let reminderHour = "reminderHour"
        static let soberAlert = "enableSoberAlert"
        static let metricUnits = "useMetricUnits"
        static let bacCurve = "showBACCurve"
    }

    // MARK: - 初始化

    init() {
        loadFromDefaults()
        isInitializing = false
    }

    private func loadFromDefaults() {
        if let raw = defaults.string(forKey: Keys.legalRegion),
           let region = LegalRegion(rawValue: raw) { selectedRegion = region }

        let savedRate = defaults.double(forKey: Keys.metabolismRate)
        if savedRate > 0 { metabolismRate = savedRate }

        if hasKey(Keys.carbonationBoost) { enableCarbonationBoost = defaults.bool(forKey: Keys.carbonationBoost) }
        if hasKey(Keys.emptyStomachBoost) { enableEmptyStomachBoost = defaults.bool(forKey: Keys.emptyStomachBoost) }
        if hasKey(Keys.customDrinkDriveLimit) { customDrinkDriveLimit = defaults.double(forKey: Keys.customDrinkDriveLimit) }
        if hasKey(Keys.customDuiLimit) { customDuiLimit = defaults.double(forKey: Keys.customDuiLimit) }
        if hasKey(Keys.testReminder) { enableTestReminder = defaults.bool(forKey: Keys.testReminder) }
        if hasKey(Keys.reminderHour) { reminderHour = defaults.integer(forKey: Keys.reminderHour) }
        if hasKey(Keys.soberAlert) { enableSoberAlert = defaults.bool(forKey: Keys.soberAlert) }
        if hasKey(Keys.metricUnits) { useMetricUnits = defaults.bool(forKey: Keys.metricUnits) }
        if hasKey(Keys.bacCurve) { showBACCurve = defaults.bool(forKey: Keys.bacCurve) }
    }

    private func hasKey(_ key: String) -> Bool {
        defaults.object(forKey: key) != nil
    }

    // MARK: - 阈值计算

    var effectiveDrinkDriveLimit: Double {
        customDrinkDriveLimit ?? selectedRegion.drinkDriveLimit
    }

    var effectiveDuiLimit: Double {
        customDuiLimit ?? selectedRegion.duiLimit
    }

    var metabolismRateFormatted: String {
        String(format: "%.3f%%/小时", metabolismRate)
    }

    /// 驾驶建议（使用当前生效阈值 — 自定义优先，否则跟随区域默认）
    /// 
    /// 内部逻辑与 `LegalRegion.drivingAdvice(for:)` 一致，
    /// 区别在于阈值来源：region 用默认阈值，此处用 effective 阈值
    func drivingAdvice(for bac: Double) -> String {
        let halfLimit = effectiveDrinkDriveLimit * 0.5
        if bac < halfLimit {
            return "✅ 可以驾驶"
        }
        if bac < effectiveDrinkDriveLimit {
            return "⚠️ 接近酒驾标准（\(selectedRegion.rawValue)），建议等待"
        }
        if bac >= effectiveDuiLimit {
            return "🚨 已达醉驾标准，严禁驾驶（\(selectedRegion.rawValue) ≥ \(String(format: "%.2f", effectiveDuiLimit))%）"
        }
        return "🚫 已达酒驾标准，禁止驾驶（\(selectedRegion.rawValue) ≥ \(String(format: "%.2f", effectiveDrinkDriveLimit))%）"
    }

    // MARK: - 重置

    func resetToDefaults() {
        Keys.all.forEach { defaults.removeObject(forKey: $0) }
        isInitializing = true
        selectedRegion = .cn
        metabolismRate = BACCalculator.defaultMetabolismRate
        enableCarbonationBoost = true
        enableEmptyStomachBoost = true
        customDrinkDriveLimit = nil
        customDuiLimit = nil
        enableTestReminder = false
        reminderHour = 20
        enableSoberAlert = true
        useMetricUnits = true
        showBACCurve = true
        isInitializing = false
    }
}

extension SettingsVM.Keys {
    /// 反射生成所有 key 值，新增 key 时自动包含
    static var all: [String] {
        Mirror(reflecting: SettingsVM.Keys.self)
            .children
            .compactMap { $0.value as? String }
    }
}
