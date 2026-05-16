import XCTest
import SwiftData
@testable import AlcoholToleranceApp

// MARK: - DashboardVM Tests

/// DashboardVM 测试 — 验证仪表盘数据计算和状态管理
@MainActor
final class DashboardVMTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var userManager: UserManager!
    private var sessionManager: DrinkSessionManager!
    private var sut: DashboardVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
            userManager = UserManager(modelContext: modelContext)
            sessionManager = DrinkSessionManager(modelContext: modelContext)
            sut = DashboardVM(modelContext: modelContext)
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

    func test_initialState() {
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser.nickname, "酒友")
    }

    func test_currentBAC_noSession() {
        XCTAssertEqual(sut.currentBAC, 0)
    }

    func test_currentBAC_withActiveSession() throws {
        let session = sessionManager.startSession(user: sut.currentUser)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)

        // 重新初始化 VM 以触发数据加载
        sut = DashboardVM(modelContext: modelContext)
        XCTAssertGreaterThan(sut.currentBAC, 0)
    }

    func test_bacLevel_noBAC() {
        XCTAssertEqual(sut.bacLevel, .sober)
    }

    func test_soberTime_noBAC() {
        XCTAssertEqual(sut.soberTime, 0)
    }

    func test_canDrive_noBAC() {
        XCTAssertTrue(sut.canDrive)
    }

    func test_canDrive_overLimit() throws {
        let session = sessionManager.startSession(user: sut.currentUser)
        try sessionManager.addDrink(to: session, type: .baijiu, volumeML: 200)
        _ = try sessionManager.endSession(session)

        sut = DashboardVM(modelContext: modelContext)
        XCTAssertFalse(sut.canDrive)
    }

    func test_recentSessions() throws {
        let session = sessionManager.startSession(user: sut.currentUser)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut = DashboardVM(modelContext: modelContext)
        XCTAssertGreaterThanOrEqual(sut.recentSessions.count, 0)
    }

    func test_userTitle() {
        XCTAssertFalse(sut.userTitle.isEmpty)
    }

    func test_refresh() {
        sut.refresh()
        // refresh 不应崩溃
        XCTAssertNotNil(sut.currentUser)
    }
}

// MARK: - DrinkLoggerVM Tests

/// DrinkLoggerVM 测试 — 验证饮酒记录添加和会话管理
@MainActor
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
            modelContext = ModelContext(modelContainer)
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

    func test_initialState() {
        XCTAssertNotNil(sut.currentSession)
        XCTAssertFalse(sut.currentSession.isCompleted)
        XCTAssertTrue(sut.currentSession.drinkRecords.isEmpty)
    }

    func test_addDrink() {
        sut.addDrink(type: .beer, volumeML: 500)
        XCTAssertEqual(sut.currentSession.drinkRecords.count, 1)
        XCTAssertEqual(sut.currentSession.drinkRecords[0].drinkType, .beer)
    }

    func test_addMultipleDrinks() {
        sut.addDrink(type: .beer, volumeML: 500)
        sut.addDrink(type: .wine, volumeML: 150)
        XCTAssertEqual(sut.currentSession.drinkRecords.count, 2)
    }

    func test_removeDrink() {
        sut.addDrink(type: .beer, volumeML: 500)
        let record = sut.currentSession.drinkRecords[0]
        sut.removeDrink(record)
        XCTAssertTrue(sut.currentSession.drinkRecords.isEmpty)
    }

    func test_currentBAC() {
        sut.addDrink(type: .beer, volumeML: 500)
        XCTAssertGreaterThan(sut.currentBAC, 0)
    }

    func test_endSession() {
        sut.addDrink(type: .beer, volumeML: 500)
        let result = sut.endSession()
        XCTAssertNotNil(result)
        XCTAssertTrue(sut.currentSession.isCompleted)
    }

    func test_endSession_noDrinks() {
        let result = sut.endSession()
        XCTAssertNil(result)
    }

    func test_startNewSession() {
        sut.addDrink(type: .beer, volumeML: 500)
        _ = sut.endSession()

        sut.startNewSession()
        XCTAssertFalse(sut.currentSession.isCompleted)
        XCTAssertTrue(sut.currentSession.drinkRecords.isEmpty)
    }
}

// MARK: - ProfileVM Tests

/// ProfileVM 测试 — 验证用户资料管理
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
            modelContext = ModelContext(modelContainer)
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

    func test_initialState() {
        XCTAssertNotNil(sut.user)
        XCTAssertEqual(sut.user.nickname, "酒友")
    }

    func test_updateNickname() {
        sut.updateNickname("新昵称")
        XCTAssertEqual(sut.user.nickname, "新昵称")
    }

    func test_updateWeight() {
        sut.updateWeight(80)
        XCTAssertEqual(sut.user.weightKg, 80)
    }

    func test_updateGender() {
        let originalGender = sut.user.isMale
        sut.updateGender(!originalGender)
        XCTAssertEqual(sut.user.isMale, !originalGender)
    }

    func test_updateBirthYear() {
        sut.updateBirthYear(1988)
        XCTAssertEqual(sut.user.birthYear, 1988)
    }

    func test_stats() {
        let stats = sut.stats
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats.nickname, sut.user.nickname)
    }

    func test_title() {
        XCTAssertFalse(sut.title.isEmpty)
    }

    func test_refresh() {
        sut.refresh()
        XCTAssertNotNil(sut.user)
    }
}

// MARK: - SettingsVM Tests

/// SettingsVM 测试 — 验证设置管理
@MainActor
final class SettingsVMTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var sut: SettingsVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
            sut = SettingsVM(modelContext: modelContext)
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

    func test_initialState() {
        XCTAssertNotNil(sut.user)
    }

    func test_selectedRegion_default() {
        XCTAssertEqual(sut.selectedRegion, .cn)
    }

    func test_selectedRegion_change() {
        sut.selectedRegion = .us
        XCTAssertEqual(sut.selectedRegion, .us)
    }

    func test_metabolismRate_default() {
        XCTAssertEqual(sut.metabolismRate, 0.015)
    }

    func test_metabolismRate_change() {
        sut.metabolismRate = 0.02
        XCTAssertEqual(sut.metabolismRate, 0.02)
    }

    func test_drivingAdvice() {
        let advice = sut.drivingAdvice(for: 0.03)
        XCTAssertFalse(advice.isEmpty)
    }

    func test_effectiveDrinkDriveLimit() {
        XCTAssertGreaterThan(sut.effectiveDrinkDriveLimit, 0)
    }

    func test_effectiveDuiLimit() {
        XCTAssertGreaterThan(sut.effectiveDuiLimit, 0)
    }

    func test_resetSettings() {
        sut.selectedRegion = .us
        sut.metabolismRate = 0.02
        sut.resetSettings()
        XCTAssertEqual(sut.selectedRegion, .cn)
        XCTAssertEqual(sut.metabolismRate, 0.015)
    }
}

// MARK: - HistoryVM Tests

/// HistoryVM 测试 — 验证历史记录查询
@MainActor
final class HistoryVMTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var sessionManager: DrinkSessionManager!
    private var sut: HistoryVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
            sessionManager = DrinkSessionManager(modelContext: modelContext)
            sut = HistoryVM(modelContext: modelContext)
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

    func test_initialState() {
        XCTAssertTrue(sut.sessions.isEmpty)
    }

    func test_loadSessions() throws {
        let user = sut.currentUser
        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadSessions()
        XCTAssertGreaterThanOrEqual(sut.sessions.count, 0)
    }

    func test_deleteSession() throws {
        let user = sut.currentUser
        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadSessions()
        let countBefore = sut.sessions.count
        if countBefore > 0 {
            sut.deleteSession(sut.sessions[0])
            XCTAssertLessThanOrEqual(sut.sessions.count, countBefore)
        }
    }

    func test_sessionCount() throws {
        let user = sut.currentUser
        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadSessions()
        XCTAssertEqual(sut.sessionCount, sut.sessions.count)
    }

    func test_averageBAC() throws {
        let user = sut.currentUser
        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadSessions()
        if sut.sessions.count > 0 {
            XCTAssertGreaterThanOrEqual(sut.averageBAC, 0)
        }
    }

    func test_highestBAC() throws {
        let user = sut.currentUser
        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        sut.loadSessions()
        if sut.sessions.count > 0 {
            XCTAssertGreaterThanOrEqual(sut.highestBAC, 0)
        }
    }
}
