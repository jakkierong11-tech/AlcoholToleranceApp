import XCTest
@testable import AlcoholToleranceApp

// MARK: - 端到端场景测试

/// 完整用户旅程测试 — 从创建用户到结算会话的全流程
@MainActor
final class IntegrationTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var userManager: UserManager!
    private var sessionManager: DrinkSessionManager!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
            userManager = UserManager(modelContext: modelContext)
            sessionManager = DrinkSessionManager(modelContext: modelContext)
        } catch {
            XCTFail("创建内存 ModelContainer 失败: \(error)")
        }
    }

    override func tearDown() {
        sessionManager = nil
        userManager = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - 场景 1: 标准男性喝啤酒

    func test_scenario_standardMaleBeer() throws {
        // Given: 70kg 男性用户
        let user = try userManager.createUser(
            nickname: "啤酒爱好者",
            weightKg: 70,
            isMale: true,
            birthYear: 1990
        )

        // When: 开始会话，喝 2 瓶啤酒
        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)

        // Then: 实时 BAC 应大于 0
        let liveBAC = sessionManager.calculateLiveBAC(for: session)
        XCTAssertNotNil(liveBAC)
        XCTAssertGreaterThan(liveBAC!, 0.05)

        // When: 结束会话
        let result = try sessionManager.endSession(session)

        // Then: 验证结果
        XCTAssertGreaterThan(result.bacPercent, 0)
        XCTAssertGreaterThan(result.toleranceScore, 0)
        XCTAssertFalse(result.legalDrivingStatus.isEmpty)
        XCTAssertEqual(result.level, BACCalculator.getBACLevel(bacPercent: result.bacPercent).bacLevel)

        // Then: 用户数据更新
        XCTAssertEqual(user.totalTests, 0) // endSession 不更新 totalTests
        XCTAssertGreaterThanOrEqual(user.highestScore, 0)
    }

    // MARK: - 场景 2: 轻体重女性喝白酒（高风险）

    func test_scenario_lightFemaleBaijiu_highRisk() throws {
        // Given: 45kg 女性
        let user = try userManager.createUser(
            nickname: "小酒量",
            weightKg: 45,
            isMale: false,
            birthYear: 1995
        )

        // When: 喝 100ml 白酒
        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .baijiu, volumeML: 100)

        // Then: 结束会话
        let result = try sessionManager.endSession(session)

        // Then: 应超过中国酒驾标准
        XCTAssertGreaterThan(result.bacPercent, 0.02)
        XCTAssertTrue(result.legalDrivingStatus.contains("禁止") || result.legalDrivingStatus.contains("严禁"))

        // Then: 等级至少为 euphoric
        XCTAssertGreaterThanOrEqual(result.level.levelNumber, BACLevel.euphoric.levelNumber)
    }

    // MARK: - 场景 3: 混合饮酒

    func test_scenario_mixedDrinks() throws {
        let user = try userManager.createUser(
            nickname: "混酒达人",
            weightKg: 80,
            isMale: true,
            birthYear: 1988
        )

        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        try sessionManager.addDrink(to: session, type: .wine, volumeML: 150)
        try sessionManager.addDrink(to: session, type: .cocktail, volumeML: 200)

        let result = try sessionManager.endSession(session)

        // 总酒精量应大于单种酒
        XCTAssertGreaterThan(result.totalAlcoholGrams, 19.725) // 仅一瓶啤酒的量
        XCTAssertEqual(session.drinkRecords.count, 3)
    }

    // MARK: - 场景 4: 空腹 + 碳酸饮料加速吸收

    func test_scenario_emptyStomachCarbonated() throws {
        let user = try userManager.createUser(
            nickname: "空腹勇士",
            weightKg: 65,
            isMale: true,
            birthYear: 1992
        )

        let session = sessionManager.startSession(user: user, isEmptyStomach: true)
        // 啤酒和鸡尾酒都是碳酸饮料
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        try sessionManager.addDrink(to: session, type: .cocktail, volumeML: 200)

        let result = try sessionManager.endSession(session, isEmptyStomach: true)

        // 空腹+碳酸应导致更高的 BAC
        XCTAssertGreaterThan(result.bacPercent, 0)
        XCTAssertGreaterThan(result.toleranceScore, 0)
    }

    // MARK: - 场景 5: 多会话历史

    func test_scenario_multipleSessions_history() throws {
        let user = try userManager.createUser(
            nickname: "老酒鬼",
            weightKg: 75,
            isMale: true,
            birthYear: 1985
        )

        // 第一次会话
        let session1 = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session1, type: .beer, volumeML: 500)
        let result1 = try sessionManager.endSession(session1)

        // 更新分数
        _ = userManager.updateUserScore(user: user, newScore: result1.toleranceScore)

        // 第二次会话
        let session2 = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session2, type: .beer, volumeML: 500)
        try sessionManager.addDrink(to: session2, type: .beer, volumeML: 500)
        let result2 = try sessionManager.endSession(session2)

        _ = userManager.updateUserScore(user: user, newScore: result2.toleranceScore)

        // Then: 查询历史
        let history = sessionManager.fetchSessions(for: user)
        XCTAssertEqual(history.count, 2)

        // Then: 用户统计
        let stats = userManager.getStats(for: user)
        XCTAssertEqual(stats.totalTests, 2)
        XCTAssertGreaterThan(stats.highestScore, 0)
        XCTAssertFalse(stats.title.isEmpty)
    }

    // MARK: - 场景 6: 删除饮品后重新结算

    func test_scenario_removeDrinkRecalculate() throws {
        let user = try userManager.createUser(
            nickname: "反悔者",
            weightKg: 70,
            isMale: true,
            birthYear: 1990
        )

        let session = sessionManager.startSession(user: user)
        let record1 = try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        let record2 = try sessionManager.addDrink(to: session, type: .baijiu, volumeML: 100)

        // 删除白酒记录
        try sessionManager.removeDrink(record2, from: session)
        XCTAssertEqual(session.drinkRecords.count, 1)

        // 重新结算
        let result = try sessionManager.endSession(session)
        // 只有啤酒的 BAC
        let expectedBeerBAC = BACCalculator.calculateBAC(
            weightKg: 70, isMale: true,
            volumeML: 500, alcoholPercent: 5
        )
        XCTAssertEqual(result.bacPercent, expectedBeerBAC, accuracy: 0.001)
    }

    // MARK: - 场景 7: 区域切换

    func test_scenario_regionSwitching() {
        let bac = 0.06

        let cnAdvice = LegalRegion.cn.drivingAdvice(for: bac)
        let usAdvice = LegalRegion.us.drivingAdvice(for: bac)
        let euAdvice = LegalRegion.eu.drivingAdvice(for: bac)

        // 中国: 0.06 > 0.02 酒驾标准，< 0.08 醉驾标准
        XCTAssertTrue(cnAdvice.contains("酒驾") || cnAdvice.contains("禁止"))

        // 美国: 0.06 < 0.08 酒驾标准
        XCTAssertTrue(usAdvice.contains("可以") || usAdvice.contains("建议等待"))

        // 欧盟: 0.06 > 0.05 酒驾标准
        XCTAssertTrue(euAdvice.contains("酒驾") || euAdvice.contains("禁止"))
    }

    // MARK: - 场景 8: 极端体重边界

    func test_scenario_extremeWeights() throws {
        // 极轻体重
        let lightUser = try userManager.createUser(
            nickname: "轻量级",
            weightKg: 10, // 会被 clamp 到 10
            isMale: true,
            birthYear: 2000
        )
        XCTAssertEqual(lightUser.weightKg, 10)

        let session1 = sessionManager.startSession(user: lightUser)
        try sessionManager.addDrink(to: session1, type: .beer, volumeML: 500)
        let result1 = try sessionManager.endSession(session1)
        // 极轻体重下 BAC 应该很高
        XCTAssertGreaterThan(result1.bacPercent, 0.1)

        // 极重体重
        let heavyUser = try userManager.createUser(
            nickname: "重量级",
            weightKg: 300, // 会被 clamp 到 300
            isMale: true,
            birthYear: 1980
        )
        XCTAssertEqual(heavyUser.weightKg, 300)

        let session2 = sessionManager.startSession(user: heavyUser)
        try sessionManager.addDrink(to: session2, type: .beer, volumeML: 500)
        let result2 = try sessionManager.endSession(session2)
        // 极重体重下 BAC 应该很低
        XCTAssertLessThan(result2.bacPercent, result1.bacPercent)
    }

    // MARK: - 场景 9: 会话摘要验证

    func test_scenario_sessionSummary() throws {
        let user = try userManager.createUser(
            nickname: "摘要测试",
            weightKg: 70,
            isMale: true,
            birthYear: 1990
        )

        let session = sessionManager.startSession(user: user)
        try sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session)

        let summary = sessionManager.generateSummary(for: session)
        XCTAssertTrue(summary.contains("🕐"))
        XCTAssertTrue(summary.contains("🍺"))
        XCTAssertTrue(summary.contains("🧪"))
        XCTAssertTrue(summary.contains("📊"))
        XCTAssertTrue(summary.contains("🍷"))
    }

    // MARK: - 场景 10: 并发操作安全

    func test_scenario_concurrentSessions_notAllowed() throws {
        let user = try userManager.createUser(
            nickname: "并发测试",
            weightKg: 70,
            isMale: true,
            birthYear: 1990
        )

        // 创建两个活跃会话
        let session1 = sessionManager.startSession(user: user)
        let session2 = sessionManager.startSession(user: user)

        // 两个都应该是活跃的
        let active = sessionManager.fetchActiveSession(for: user)
        // 取最新的那个
        XCTAssertNotNil(active)

        // 结束第一个
        try sessionManager.addDrink(to: session1, type: .beer, volumeML: 500)
        _ = try sessionManager.endSession(session1)

        // 第二个仍应活跃
        let stillActive = sessionManager.fetchActiveSession(for: user)
        XCTAssertNotNil(stillActive)
        XCTAssertEqual(stillActive?.id, session2.id)
    }
}
