import XCTest
import SwiftData
@testable import AlcoholToleranceApp

// MARK: - DashboardVM Tests

/// DashboardVM 测试 �?验证仪表盘数据聚合和刷新
@MainActor
final class DashboardVMTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var sessionManager: DrinkSessionManager!
    private var sut: DashboardVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
            sessionManager = DrinkSessionManager(modelContext: modelContext)
            sut = DashboardVM(modelContext: modelContext)
        } catch {
            XCTFail("创建内存 ModelContainer 失败: \(error)")
        }
    }

    override func tearDown() {
        sut = nil
        sessionManager = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - 初始状�?
    func test_init_createsDefaultUser() {
        XCTAssertNotNil(sut.user)
        XCTAssertEqual(sut.user.nickname, "酒友")
    }

    func test_init_currentBAC_isZero() {
        XCTAssertEqual(sut.currentBAC, 0)
    }

    func test_init_recentSessions_isEmpty() {
        XCTAssertTrue(sut.recentSessions.isEmpty)
    }

    func test_init_peakBAC_isZero() {
        XCTAssertEqual(sut.peakBAC, 0)
    }

    func test_init_bacLevel_isSober() {
        XCTAssertEqual(sut.bacLevel, .sober)
    }

    // MARK: - 计算属�?
    func test_nickname_returnsUserName() {
        XCTAssertEqual(sut.nickname, sut.user.nickname)
    }

    func test_genderLabel_returnsChinese() {
        XCTAssertTrue(sut.genderLabel == "男�? || sut.genderLabel == "女�?)
    }

    func test_weightKg_returnsUserWeight() {
        XCTAssertEqual(sut.weightKg, sut.user.weightKg)
    }

    func test_toleranceTitle_notEmpty() {
        XCTAssertFalse(sut.toleranceTitle.isEmpty)
    }

    func test_widmarkFactor_matchesUser() {
        XCTAssertEqual(sut.widmarkFactor, sut.user.widmarkFactor)
    }

    func test_canStartTest_withValidWeight() {
        // 默认 65kg，在 10-300 范围�?        XCTAssertTrue(sut.canStartTest)
    }

    func test_hasHistory_initiallyFalse() {
        XCTAssertFalse(sut.hasHistory)
    }

    func test_safeGuideline_notEmpty() {
        XCTAssertFalse(sut.safeGuideline.isEmpty)
    }

    func test_maxStandardUnits_positive() {
        XCTAssertGreaterThan(sut.maxStandardUnits, 0)
    }

    func test_hasTestedToday_initiallyFalse() {
        XCTAssertFalse(sut.hasTestedToday)
    }

    func test_lastTestSummary_initiallyNil() {
        XCTAssertNil(sut.lastTestSummary)
    }

    func test_sessionScore_initiallyZero() {
        XCTAssertEqual(sut.sessionScore, 0)
    }

    // MARK: - 刷新后状�?
    func test_refresh_doesNotCrash() {
        sut.refresh()
        XCTAssertNotNil(sut.user)
    }

    func test_currentBAC_afterSession() throws {
        let session = sessionManager.startSession(user: sut.user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        // 创建�?VM 触发数据加载
        let newVM = DashboardVM(modelContext: modelContext)
        XCTAssertGreaterThan(newVM.currentBAC, 0)
    }

    func test_hasHistory_afterSession() throws {
        let session = sessionManager.startSession(user: sut.user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        let newVM = DashboardVM(modelContext: modelContext)
        XCTAssertTrue(newVM.hasHistory)
    }

    func test_peakBAC_afterSession() throws {
        let session = sessionManager.startSession(user: sut.user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        let newVM = DashboardVM(modelContext: modelContext)
        XCTAssertGreaterThan(newVM.peakBAC, 0)
    }

    func test_bacLevel_afterHighBAC() throws {
        let session = sessionManager.startSession(user: sut.user)
        try sessionManager.addDrink(to: session, type: .baijiu, volumeML: 200)
        _ = try sessionManager.endSession(session)

        let newVM = DashboardVM(modelContext: modelContext)
        // 200ml 白酒应至少达�?mild 等级
        XCTAssertGreaterThanOrEqual(newVM.bacLevel.levelNumber, BACLevel.mild.levelNumber)
    }
}

// MARK: - DrinkLoggerVM Tests

/// DrinkLoggerVM 测试 �?验证饮酒记录和预估功�?@MainActor
final class DrinkLoggerVMTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var sut: DrinkLoggerVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
            sut = DrinkLoggerVM(modelContext: modelContext)
        } catch {
            XCTFail("创建内存 ModelContainer 失败: \(error)")
        }
    }

    override func tearDown() {
        sut = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - 初始状�?
    func test_init_stateIsIdle() {
        XCTAssertEqual(sut.state, .idle)
    }

    func test_init_selectedDrinkType_isBeer() {
        XCTAssertEqual(sut.selectedDrinkType, .beer)
    }

    func test_init_volumeMl_is500() {
        XCTAssertEqual(sut.volumeMl, 500)
    }

    func test_init_abv_is5() {
        XCTAssertEqual(sut.abv, 5.0)
    }

    func test_init_loggedDrinks_isEmpty() {
        XCTAssertTrue(sut.loggedDrinks.isEmpty)
    }

    func test_init_legalRegion_isCN() {
        XCTAssertEqual(sut.legalRegion, .cn)
    }

    // MARK: - 饮品类型切换

    func test_setDrinkType_updatesSelectedType() {
        sut.setDrinkType(.baijiu)
        XCTAssertEqual(sut.selectedType, .baijiu)
    }

    func test_setDrinkType_updatesVolumeToDefault() {
        sut.setDrinkType(.wine)
        XCTAssertEqual(sut.volumeMl, 150) // 红酒默认 150ml
    }

    func test_setDrinkType_updatesAbvToDefault() {
        sut.setDrinkType(.baijiu)
        XCTAssertEqual(sut.abv, 52.0)
    }

    func test_setDrinkType_beer_setsCarbonated() {
        sut.setDrinkType(.beer)
        XCTAssertTrue(sut.isCarbonated)
    }

    func test_setDrinkType_cocktail_setsCarbonated() {
        sut.setDrinkType(.cocktail)
        XCTAssertTrue(sut.isCarbonated)
    }

    func test_setDrinkType_wine_setsNoncarbonated() {
        sut.setDrinkType(.wine)
        XCTAssertFalse(sut.isCarbonated)
    }

    // MARK: - 预估功能

    func test_estimateSingleDrinkBAC_positiveResult() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.abv = 5.0
        sut.estimateSingleDrinkBAC()
        XCTAssertNotNil(sut.estimatedBAC)
        XCTAssertGreaterThan(sut.estimatedBAC!, 0)
    }

    func test_estimateSingleDrinkBAC_setsLevel() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.abv = 5.0
        sut.estimateSingleDrinkBAC()
        XCTAssertNotNil(sut.estimatedLevel)
        XCTAssertNotNil(sut.estimatedLevelColor)
    }

    func test_estimateSingleDrinkBAC_carbonated_higher() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.abv = 5.0

        sut.isCarbonated = false
        sut.estimateSingleDrinkBAC()
        let nonCarbonatedBAC = sut.estimatedBAC

        sut.isCarbonated = true
        sut.estimateSingleDrinkBAC()
        let carbonatedBAC = sut.estimatedBAC

        if let nc = nonCarbonatedBAC, let c = carbonatedBAC {
            XCTAssertGreaterThan(c, nc, "碳酸饮品 BAC 应更�?)
        }
    }

    func test_estimateSingleDrinkBAC_emptyStomach_higher() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.abv = 5.0

        sut.isEmptyStomach = false
        sut.estimateSingleDrinkBAC()
        let fedBAC = sut.estimatedBAC

        sut.isEmptyStomach = true
        sut.estimateSingleDrinkBAC()
        let emptyBAC = sut.estimatedBAC

        if let f = fedBAC, let e = emptyBAC {
            XCTAssertGreaterThan(e, f, "空腹 BAC 应更�?)
        }
    }

    func test_calculateStandardDrinks_beer() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.abv = 5.0
        sut.calculateStandardDrinks()
        // 500 * 0.05 * 0.789 / 10 �?1.97
        XCTAssertGreaterThan(sut.standardDrinks, 1.5)
        XCTAssertLessThan(sut.standardDrinks, 2.5)
    }

    // MARK: - 日志操作

    func test_logDrink_addsToLoggedDrinks() {
        sut.setDrinkType(.beer)
        sut.logDrink()
        XCTAssertEqual(sut.loggedDrinks.count, 1)
        XCTAssertEqual(sut.state, .done)
    }

    func test_logDrink_recordsCorrectType() {
        sut.setDrinkType(.wine)
        sut.logDrink()
        XCTAssertEqual(sut.loggedDrinks.first?.drinkType, .wine)
    }

    func test_logMultipleDrinks_incrementsCount() {
        sut.logDrink()
        sut.logDrink()
        XCTAssertEqual(sut.loggedDrinks.count, 2)
    }

    func test_cancelLastDrink_removesLast() {
        sut.logDrink()
        sut.logDrink()
        sut.cancelLastDrink()
        XCTAssertEqual(sut.loggedDrinks.count, 1)
    }

    func test_cancelLastDrink_empty_logsNoCrash() {
        sut.cancelLastDrink() // 不应崩溃
        XCTAssertTrue(sut.loggedDrinks.isEmpty)
    }

    func test_clearLogs_removesAll() {
        sut.logDrink()
        sut.logDrink()
        sut.clearLogs()
        XCTAssertTrue(sut.loggedDrinks.isEmpty)
    }

    func test_removeLog_atValidIndex() {
        sut.logDrink()
        sut.logDrink()
        sut.removeLog(at: 0)
        XCTAssertEqual(sut.loggedDrinks.count, 1)
    }

    func test_removeLog_atInvalidIndex_noCrash() {
        sut.logDrink()
        sut.removeLog(at: 999) // 不应崩溃
        XCTAssertEqual(sut.loggedDrinks.count, 1)
    }

    // MARK: - 计算属�?
    func test_totalStandardDrinks_accumulates() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.abv = 5.0
        sut.calculateStandardDrinks()
        sut.logDrink()
        sut.logDrink()
        XCTAssertGreaterThan(sut.totalStandardDrinks, sut.standardDrinks)
    }

    func test_totalVolumeMl_accumulates() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.logDrink()
        sut.logDrink()
        XCTAssertEqual(sut.totalVolumeMl, 1000)
    }

    func test_totalAlcoholGrams_positive() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.abv = 5.0
        sut.logDrink()
        XCTAssertGreaterThan(sut.totalAlcoholGrams, 0)
    }

    func test_isOverLegalLimit_belowThreshold() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 100
        sut.abv = 3.0
        sut.estimateSingleDrinkBAC()
        XCTAssertFalse(sut.isOverLegalLimit)
    }

    func test_drivingAdvice_notEmpty() {
        sut.setDrinkType(.beer)
        sut.volumeMl = 500
        sut.abv = 5.0
        sut.estimateSingleDrinkBAC()
        XCTAssertFalse(sut.drivingAdvice.isEmpty)
    }
}

// MARK: - ProfileVM Tests

/// ProfileVM 测试 �?验证用户资料管理
@MainActor
final class ProfileVMTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var sut: ProfileVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
            sut = ProfileVM(modelContext: modelContext)
        } catch {
            XCTFail("创建内存 ModelContainer 失败: \(error)")
        }
    }

    override func tearDown() {
        sut = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - 初始状�?
    func test_init_createsDefaultUser() {
        XCTAssertNotNil(sut.user)
        XCTAssertEqual(sut.user.nickname, "酒友")
    }

    func test_init_showSaveConfirmation_isFalse() {
        XCTAssertFalse(sut.showSaveConfirmation)
    }

    // MARK: - 更新操作

    func test_updateNickname_changesName() {
        sut.updateNickname("新名�?)
        XCTAssertEqual(sut.user.nickname, "新名�?)
    }

    func test_updateNickname_empty_doesNotCrash() {
        sut.updateNickname("")
        // 空字符串更新不应崩溃
    }

    func test_updateWeight_changesWeight() {
        sut.updateWeight(80)
        XCTAssertEqual(sut.user.weightKg, 80)
    }

    func test_updateWeight_negative_clamped() {
        sut.updateWeight(-10)
        XCTAssertEqual(sut.user.weightKg, 10) // clamp �?10
    }

    func test_updateWeight_excessive_clamped() {
        sut.updateWeight(500)
        XCTAssertEqual(sut.user.weightKg, 300) // clamp �?300
    }

    func test_updateGender_isMale_trueToFalse() {
        let original = sut.user.isMale
        sut.updateGender(isMale: !original)
        XCTAssertEqual(sut.user.isMale, !original)
    }

    func test_updateGender_updatesWidmarkFactor() {
        sut.updateGender(isMale: true)
        XCTAssertEqual(sut.widmarkFactor, 0.68)
        sut.updateGender(isMale: false)
        XCTAssertEqual(sut.widmarkFactor, 0.55)
    }

    func test_saveProfile_setsConfirmation() {
        sut.saveProfile()
        XCTAssertTrue(sut.showSaveConfirmation)
    }

    // MARK: - 计算属�?
    func test_title_notEmpty() {
        XCTAssertFalse(sut.title.isEmpty)
    }

    func test_highestScore_initiallyZero() {
        XCTAssertEqual(sut.highestScore, 0)
    }

    func test_totalSessions_initiallyZero() {
        XCTAssertEqual(sut.totalSessions, 0)
    }

    func test_genderLabel_returnsChinese() {
        XCTAssertTrue(sut.genderLabel == "男�? || sut.genderLabel == "女�?)
    }

    func test_widmarkFactor_positive() {
        XCTAssertGreaterThan(sut.widmarkFactor, 0)
    }

    func test_toleranceTitle_notEmpty() {
        XCTAssertFalse(sut.toleranceTitle.isEmpty)
    }

    // MARK: - 数据刷新

    func test_loadProfile_doesNotCrash() {
        sut.loadProfile()
        XCTAssertNotNil(sut.user)
    }

    func test_resetAllData_clearsConfirmation() {
        sut.saveProfile()
        XCTAssertTrue(sut.showSaveConfirmation)
        sut.resetAllData()
        XCTAssertFalse(sut.showSaveConfirmation)
    }
}

// MARK: - SettingsVM Tests

/// SettingsVM 测试 �?验证设置管理
/// 注意: SettingsVM 使用 UserDefaults 持久化，无需 ModelContext
final class SettingsVMTests: XCTestCase {

    private var sut: SettingsVM!

    override func setUp() {
        super.setUp()
        sut = SettingsVM()
    }

    override func tearDown() {
        sut.resetAllData()
        sut = nil
        super.tearDown()
    }

    // MARK: - 初始状�?
    func test_init_selectedRegion_isCN() {
        XCTAssertEqual(sut.selectedRegion, .cn)
    }

    func test_init_metabolismRate_isDefault() {
        XCTAssertEqual(sut.metabolismRate, 0.015)
    }

    func test_init_enableCarbonationBoost_isTrue() {
        XCTAssertTrue(sut.enableCarbonationBoost)
    }

    func test_init_enableEmptyStomachBoost_isTrue() {
        XCTAssertTrue(sut.enableEmptyStomachBoost)
    }

    func test_init_theme_isNeon() {
        XCTAssertEqual(sut.theme, .neon)
    }

    // MARK: - 区域切换

    func test_setRegion_changesSelectedRegion() {
        sut.setRegion(.us)
        XCTAssertEqual(sut.selectedRegion, .us)
        XCTAssertEqual(sut.region, .us)
    }

    func test_setRegion_updatesRegionAlias() {
        sut.setRegion(.eu)
        XCTAssertEqual(sut.region, .eu)
    }

    // MARK: - 代谢�?
    func test_setMetabolismRate_updatesValue() {
        sut.setMetabolismRate(0.02)
        XCTAssertEqual(sut.metabolismRate, 0.02)
    }

    func test_metabolismRate_clampedToMin() {
        sut.setMetabolismRate(0.001)
        XCTAssertEqual(sut.metabolismRate, 0.005)
    }

    func test_metabolismRate_clampedToMax() {
        sut.setMetabolismRate(0.05)
        XCTAssertEqual(sut.metabolismRate, 0.030)
    }

    // MARK: - 计算属�?
    func test_effectiveDrinkDriveLimit_defaultsToCN() {
        XCTAssertEqual(sut.effectiveDrinkDriveLimit, LegalRegion.cn.drinkDriveLimit)
    }

    func test_effectiveDuiLimit_defaultsToCN() {
        XCTAssertEqual(sut.effectiveDuiLimit, LegalRegion.cn.duiLimit)
    }

    func test_metabolismRateFormatted_containsPercent() {
        XCTAssertTrue(sut.metabolismRateFormatted.contains("%"))
    }

    // MARK: - 驾驶建议

    func test_drivingAdvice_sober_containsCanDrive() {
        let advice = sut.drivingAdvice(for: 0.005)
        XCTAssertTrue(advice.contains("可以驾驶"))
    }

    func test_drivingAdvice_overLimit_containsWarning() {
        let advice = sut.drivingAdvice(for: 0.03)
        XCTAssertTrue(advice.contains("禁止") || advice.contains("严禁"))
    }

    // MARK: - 自定义阈�?
    func test_customDrinkDriveLimit_overridesEffective() {
        sut.customDrinkDriveLimit = 0.05
        XCTAssertEqual(sut.effectiveDrinkDriveLimit, 0.05)
    }

    func test_customDuiLimit_overridesEffective() {
        sut.customDuiLimit = 0.10
        XCTAssertEqual(sut.effectiveDuiLimit, 0.10)
    }

    // MARK: - 重置

    func test_resetAllData_restoresDefaults() {
        sut.setRegion(.us)
        sut.setMetabolismRate(0.02)
        sut.resetAllData()

        XCTAssertEqual(sut.selectedRegion, .cn)
        XCTAssertEqual(sut.metabolismRate, 0.015)
    }
}

// MARK: - HistoryVM Tests

/// HistoryVM 测试 �?验证历史记录查询和管�?@MainActor
final class HistoryVMTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var sessionManager: DrinkSessionManager!
    private var userManager: UserManager!
    private var sut: HistoryVM!
    private var testUser: User!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
            userManager = UserManager(modelContext: modelContext)
            sessionManager = DrinkSessionManager(modelContext: modelContext)
            testUser = userManager.fetchOrCreateUser()
            sut = HistoryVM(modelContext: modelContext)
            sut.setUser(testUser)
        } catch {
            XCTFail("创建内存 ModelContainer 失败: \(error)")
        }
    }

    override func tearDown() {
        sut = nil
        sessionManager = nil
        userManager = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - 初始状�?
    func test_init_sessions_isEmpty() {
        XCTAssertTrue(sut.sessions.isEmpty)
    }

    func test_init_results_isEmpty() {
        XCTAssertTrue(sut.results.isEmpty)
    }

    func test_init_filter_isAll() {
        XCTAssertEqual(sut.filter, .all)
    }

    func test_init_isLoading_isFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_init_selectedResult_isNil() {
        XCTAssertNil(sut.selectedResult)
    }

    // MARK: - 计算属�?
    func test_totalTests_initiallyZero() {
        XCTAssertEqual(sut.totalTests, 0)
    }

    func test_peakBAC_initiallyZero() {
        XCTAssertEqual(sut.peakBAC, 0)
    }

    func test_toleranceTitle_notEmpty() {
        XCTAssertFalse(sut.toleranceTitle.isEmpty)
    }

    // MARK: - 加载会话

    func test_loadAll_withCompletedSession_incrementsCount() throws {
        let session = sessionManager.startSession(user: testUser)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadAll()
        XCTAssertGreaterThanOrEqual(sut.sessions.count, 1)
    }

    func test_loadAll_setsPeakBAC() throws {
        let session = sessionManager.startSession(user: testUser)
        try sessionManager.addDrink(to: session, type: .baijiu, volumeML: 100)
        _ = try sessionManager.endSession(session)

        sut.loadAll()
        XCTAssertGreaterThan(sut.peakBAC, 0)
    }

    func test_loadHistory_async_togglesLoading() async throws {
        let session = sessionManager.startSession(user: testUser)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        await sut.loadHistory()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - 筛�?
    func test_applyFilter_today() throws {
        let session = sessionManager.startSession(user: testUser)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadAll()
        sut.applyFilter(.today)
        XCTAssertEqual(sut.filter, .today)
    }

    func test_applyFilter_all() {
        sut.applyFilter(.all)
        XCTAssertEqual(sut.filter, .all)
    }

    func test_applyFilter_highScore() {
        sut.applyFilter(.highScore)
        XCTAssertEqual(sut.filter, .highScore)
    }

    // MARK: - 删除

    func test_deleteSession_byID_removesFromList() throws {
        let session = sessionManager.startSession(user: testUser)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadAll()
        let countBefore = sut.sessions.count
        guard countBefore > 0 else { return }

        sut.deleteSession(sut.sessions[0].id)
        XCTAssertLessThan(sut.sessions.count, countBefore)
    }

    func test_deleteSession_byIndex_removesFromList() throws {
        let session = sessionManager.startSession(user: testUser)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadAll()
        let countBefore = sut.sessions.count
        guard countBefore > 0 else { return }

        sut.deleteSession(at: 0)
        XCTAssertLessThan(sut.sessions.count, countBefore)
    }

    func test_deleteSession_invalidID_noCrash() {
        sut.deleteSession(UUID()) // 不存在的 ID，不应崩�?    }

    func test_deleteSession_invalidIndex_noCrash() {
        sut.deleteSession(at: 999) // 超界索引，不应崩�?    }
}

// MARK: - SoberTestVM Tests

/// SoberTestVM 测试 �?验证清醒测试�?BAC 计算
@MainActor
final class SoberTestVMTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var sut: SoberTestVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer.mainContext
            sut = SoberTestVM(modelContext: modelContext)
        } catch {
            XCTFail("创建内存 ModelContainer 失败: \(error)")
        }
    }

    override func tearDown() {
        sut = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - 初始状�?
    func test_init_testType_isReaction() {
        XCTAssertEqual(sut.testType, .reaction)
    }

    func test_init_inputMode_isBacDirect() {
        XCTAssertEqual(sut.inputMode, .bacDirect)
    }

    func test_init_legalRegion_isCN() {
        XCTAssertEqual(sut.legalRegion, .cn)
    }

    func test_init_currentBAC_isCalculated() {
        // init 调用 recalculate(), 默认 inputBAC=0.08
        XCTAssertGreaterThan(sut.currentBAC, 0)
    }

    func test_init_bacLevel_notSober() {
        // 0.08 �?BAC 不应该返�?sober
        // 需要确认实际等级：0.08 �?euphoric(0.06) �?excited(0.10) 之间
        XCTAssertEqual(sut.bacLevel, .euphoric)
    }

    // MARK: - 计算属�?
    func test_soberHours_positive() {
        XCTAssertGreaterThan(sut.soberHours, 0)
    }

    func test_soberTimeFormatted_notEmpty() {
        XCTAssertFalse(sut.soberTimeFormatted.isEmpty)
    }

    func test_BACFormatted_notEmpty() {
        XCTAssertFalse(sut.BACFormatted.isEmpty)
    }

    func test_drivingStatusText_notEmpty() {
        XCTAssertFalse(sut.drivingStatusText.isEmpty)
    }

    func test_metabolismRateLabel_containsPercent() {
        XCTAssertTrue(sut.metabolismRateLabel.contains("%"))
    }

    func test_bacCurvePoints_notEmpty() {
        XCTAssertFalse(sut.bacCurvePoints.isEmpty)
    }

    // MARK: - 输入模式切换

    func test_onInputModeChanged_switchesToDrinkBased() {
        sut.inputMode = .drinkBased
        sut.onInputModeChanged()
        XCTAssertGreaterThan(sut.totalAlcoholGrams, 0)
    }

    func test_onDrinkTypeChanged_updatesDefaults() {
        sut.selectedDrinkType = .baijiu
        sut.onDrinkTypeChanged()
        XCTAssertEqual(sut.drinkVolumeMl, 50) // 白酒默认 50ml
        XCTAssertEqual(sut.drinkABV, 52.0)
    }

    func test_recalculate_withZeroBAC() {
        sut.inputMode = .bacDirect
        sut.inputBAC = 0.0
        sut.recalculate()
        XCTAssertEqual(sut.currentBAC, 0)
        XCTAssertEqual(sut.bacLevel, .sober)
    }

    // MARK: - 测试结果

    func test_submitReactionTime_setsLastResult() {
        sut.submitReactionTime(250)
        XCTAssertNotNil(sut.lastResult)
        XCTAssertEqual(sut.lastResult?.score, 250)
        XCTAssertEqual(sut.lastResult?.timeMs, 250)
    }

    func test_submitBalanceTest_setsLastResult() {
        sut.submitBalanceTest(85)
        XCTAssertNotNil(sut.lastResult)
        XCTAssertEqual(sut.lastResult?.score, 85)
    }

    func test_submitMemoryTest_calculatesScore() {
        sut.submitMemoryTest(8, 10)
        XCTAssertNotNil(sut.lastResult)
        XCTAssertEqual(sut.lastResult?.score, 80)
    }

    func test_submitMemoryTest_zeroItems_noDivisionByZero() {
        sut.submitMemoryTest(0, 0)
        XCTAssertNotNil(sut.lastResult)
        XCTAssertEqual(sut.lastResult?.score, 0)
    }

    // MARK: - 代谢率影�?
    func test_higherMetabolismRate_lowerSoberTime() {
        sut.inputBAC = 0.08
        sut.metabolismRate = 0.015
        sut.recalculate()
        let slowSober = sut.soberHours

        sut.metabolismRate = 0.030
        sut.recalculate()
        let fastSober = sut.soberHours

        XCTAssertLessThan(fastSober, slowSober, "代谢�?= 醒酒时间�?)
    }

    func test_maxCurveBAC_positive() {
        XCTAssertGreaterThan(sut.maxCurveBAC, 0)
    }
}
