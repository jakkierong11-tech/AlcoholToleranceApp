import XCTest
import SwiftData
@testable import AlcoholToleranceApp

// MARK: - UserManager Tests

/// UserManager 服务测试 — 需要 SwiftData 上下文，使用内存存储
@MainActor
final class UserManagerTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var sut: UserManager!

    override func setUp() {
        super.setUp()
        // 使用内存存储的 SwiftData 容器
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
            sut = UserManager(modelContext: modelContext)
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

    // MARK: - 创建用户

    func test_createUser_success() throws {
        let user = try sut.createUser(
            nickname: "测试用户",
            weightKg: 70.0,
            isMale: true,
            birthYear: 1990
        )

        XCTAssertEqual(user.nickname, "测试用户")
        XCTAssertEqual(user.weightKg, 70.0)
        XCTAssertTrue(user.isMale)
        XCTAssertEqual(user.birthYear, 1990)
    }

    func test_createUser_emptyNickname_throws() {
        XCTAssertThrowsError(try sut.createUser(nickname: "   ")) { error in
            XCTAssertTrue(error is UserError)
        }
    }

    func test_createUser_zeroWeight_throws() {
        XCTAssertThrowsError(try sut.createUser(weightKg: 0)) { error in
            XCTAssertTrue(error is UserError)
        }
    }

    func test_createUser_negativeWeight_throws() {
        XCTAssertThrowsError(try sut.createUser(weightKg: -10)) { error in
            XCTAssertTrue(error is UserError)
        }
    }

    func test_createUser_invalidBirthYear_throws() {
        XCTAssertThrowsError(try sut.createUser(birthYear: 1800)) { error in
            XCTAssertTrue(error is UserError)
        }
    }

    func test_createUser_futureBirthYear_throws() {
        let futureYear = Calendar.current.component(.year, from: Date()) + 10
        XCTAssertThrowsError(try sut.createUser(birthYear: futureYear)) { error in
            XCTAssertTrue(error is UserError)
        }
    }

    func test_createUser_duplicate_throws() throws {
        _ = try sut.createUser(nickname: "用户A")
        XCTAssertThrowsError(try sut.createUser(nickname: "用户B")) { error in
            XCTAssertTrue(error is UserError)
            if case UserError.userAlreadyExists = error {
                // 正确
            } else {
                XCTFail("应为 userAlreadyExists 错误")
            }
        }
    }

    // MARK: - 查询用户

    func test_fetchCurrentUser_noUser_returnsNil() {
        XCTAssertNil(sut.fetchCurrentUser())
    }

    func test_fetchCurrentUser_afterCreate_returnsUser() throws {
        let created = try sut.createUser(nickname: "老王")
        let fetched = sut.fetchCurrentUser()
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.nickname, "老王")
        XCTAssertEqual(fetched?.id, created.id)
    }

    func test_fetchOrCreateUser_noUser_createsDefault() {
        let user = sut.fetchOrCreateUser()
        XCTAssertEqual(user.nickname, "酒友")
        XCTAssertEqual(user.weightKg, 65.0)
    }

    func test_fetchOrCreateUser_existingUser_returnsExisting() throws {
        let created = try sut.createUser(nickname: " Existing ")
        let fetched = sut.fetchOrCreateUser()
        XCTAssertEqual(fetched.id, created.id)
        XCTAssertEqual(fetched.nickname, "Existing") // 去除空格
    }

    func test_fetchUserById() throws {
        let user = try sut.createUser(nickname: "按ID查")
        let fetched = sut.fetchUser(by: user.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.nickname, "按ID查")
    }

    func test_fetchUserById_notFound_returnsNil() {
        XCTAssertNil(sut.fetchUser(by: UUID()))
    }

    func test_fetchAllUsers() throws {
        // 单用户模式下只能创建一个
        _ = try sut.createUser(nickname: "唯一用户")
        let all = sut.fetchAllUsers()
        XCTAssertEqual(all.count, 1)
    }

    // MARK: - 更新用户

    func test_updateProfile_nickname() throws {
        let user = try sut.createUser(nickname: "旧名")
        try sut.updateProfile(user: user, nickname: "新名")
        XCTAssertEqual(user.nickname, "新名")
    }

    func test_updateProfile_weight() throws {
        let user = try sut.createUser(nickname: "测试", weightKg: 60)
        try sut.updateProfile(user: user, weightKg: 75)
        XCTAssertEqual(user.weightKg, 75)
    }

    func test_updateProfile_invalidWeight_throws() throws {
        let user = try sut.createUser(nickname: "测试")
        XCTAssertThrowsError(try sut.updateProfile(user: user, weightKg: 0)) { error in
            XCTAssertTrue(error is UserError)
        }
    }

    func test_updateProfile_gender() throws {
        let user = try sut.createUser(nickname: "测试", isMale: true)
        try sut.updateProfile(user: user, isMale: false)
        XCTAssertFalse(user.isMale)
        XCTAssertEqual(user.widmarkFactor, 0.55)
    }

    func test_updateProfile_birthYear() throws {
        let user = try sut.createUser(nickname: "测试", birthYear: 1990)
        try sut.updateProfile(user: user, birthYear: 1985)
        XCTAssertEqual(user.birthYear, 1985)
    }

    func test_updateProfile_invalidBirthYear_throws() throws {
        let user = try sut.createUser(nickname: "测试")
        XCTAssertThrowsError(try sut.updateProfile(user: user, birthYear: 1800)) { error in
            XCTAssertTrue(error is UserError)
        }
    }

    func test_updateProfile_updatesLastActiveAt() throws {
        let user = try sut.createUser(nickname: "测试")
        let before = user.lastActiveAt
        Thread.sleep(forTimeInterval: 0.01)
        try sut.updateProfile(user: user, nickname: "新名")
        XCTAssertGreaterThan(user.lastActiveAt.timeIntervalSince1970, before.timeIntervalSince1970)
    }

    // MARK: - 分数更新

    func test_updateUserScore_newRecord() throws {
        let user = try sut.createUser(nickname: "测试")
        let isNewRecord = sut.updateUserScore(user: user, newScore: 80)
        XCTAssertTrue(isNewRecord)
        XCTAssertEqual(user.highestScore, 80)
        XCTAssertEqual(user.totalTests, 1)
    }

    func test_updateUserScore_notNewRecord() throws {
        let user = try sut.createUser(nickname: "测试")
        _ = sut.updateUserScore(user: user, newScore: 80)
        let isNewRecord = sut.updateUserScore(user: user, newScore: 60)
        XCTAssertFalse(isNewRecord)
        XCTAssertEqual(user.highestScore, 80) // 最高分不变
        XCTAssertEqual(user.totalTests, 2)
    }

    func test_updateUserScore_negativeScore_ignored() throws {
        let user = try sut.createUser(nickname: "测试")
        let isNewRecord = sut.updateUserScore(user: user, newScore: -10)
        XCTAssertFalse(isNewRecord)
        XCTAssertEqual(user.totalTests, 0) // 不应增加
    }

    func test_updateUserScore_over100_ignored() throws {
        let user = try sut.createUser(nickname: "测试")
        let isNewRecord = sut.updateUserScore(user: user, newScore: 150)
        XCTAssertFalse(isNewRecord)
        XCTAssertEqual(user.totalTests, 0)
    }

    func test_updateUserScore_exactly100() throws {
        let user = try sut.createUser(nickname: "测试")
        let isNewRecord = sut.updateUserScore(user: user, newScore: 100)
        XCTAssertTrue(isNewRecord)
        XCTAssertEqual(user.highestScore, 100)
    }

    // MARK: - 称号系统

    func test_getUserTitle_allRanges() {
        let testCases: [(score: Double, expectedName: String)] = [
            (-10, "新手村"),
            (0, "新手村"),
            (10, "新手村"),
            (20, "入门选手"),
            (30, "入门选手"),
            (40, "酒场熟客"),
            (50, "酒场熟客"),
            (60, "海量选手"),
            (70, "海量选手"),
            (80, "酒神降临"),
            (90, "酒神降临"),
            (95, "千杯不醉"),
            (100, "千杯不醉"),
        ]

        for tc in testCases {
            let title = UserManager.getUserTitle(for: tc.score)
            XCTAssertEqual(title.name, tc.expectedName,
                "分数 \(tc.score) 应映射到 \(tc.expectedName)，实际: \(title.name)")
        }
    }

    func test_getCurrentTitle() throws {
        let user = try sut.createUser(nickname: "测试", highestScore: 75)
        let title = sut.getCurrentTitle(for: user)
        XCTAssertEqual(title.name, "海量选手")
    }

    func test_getStats() throws {
        let user = try sut.createUser(
            nickname: "统计测试",
            weightKg: 80,
            isMale: false,
            birthYear: 1988
        )
        _ = sut.updateUserScore(user: user, newScore: 85)

        let stats = sut.getStats(for: user)
        XCTAssertEqual(stats.nickname, "统计测试")
        XCTAssertEqual(stats.weightKg, 80)
        XCTAssertEqual(stats.genderLabel, "女")
        XCTAssertEqual(stats.highestScore, 85)
        XCTAssertEqual(stats.totalTests, 1)
        XCTAssertTrue(stats.title.contains("酒神降临"))
        XCTAssertNotNil(stats.titleDetail)
        XCTAssertEqual(stats.formattedWeight, "80.0 kg")
        XCTAssertEqual(stats.formattedScore, "85 / 100")
        XCTAssertEqual(stats.improvementRate, "1 次测试")
    }

    // MARK: - 删除用户

    func test_deleteUser() throws {
        let user = try sut.createUser(nickname: "待删除")
        try sut.deleteUser(user)
        XCTAssertNil(sut.fetchCurrentUser())
    }
}

// MARK: - DrinkSessionManager Tests

/// DrinkSessionManager 服务测试 — 验证会话生命周期
@MainActor
final class DrinkSessionManagerTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var userManager: UserManager!
    private var sut: DrinkSessionManager!
    private var testUser: User!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
            userManager = UserManager(modelContext: modelContext)
            sut = DrinkSessionManager(modelContext: modelContext)
            testUser = userManager.fetchOrCreateUser()
        } catch {
            XCTFail("创建内存 ModelContainer 失败: \(error)")
        }
    }

    override func tearDown() {
        sut = nil
        userManager = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - 会话创建

    func test_startSession_createsActiveSession() {
        let session = sut.startSession(user: testUser)
        XCTAssertNotNil(session.id)
        XCTAssertFalse(session.isCompleted)
        XCTAssertNil(session.endTime)
        XCTAssertTrue(session.drinkRecords.isEmpty)
        XCTAssertEqual(session.user?.id, testUser.id)
    }

    func test_startSession_withoutUser() {
        let session = sut.startSession(user: nil)
        XCTAssertNil(session.user)
        XCTAssertFalse(session.isCompleted)
    }

    // MARK: - 添加饮品

    func test_addDrink_success() throws {
        let session = sut.startSession(user: testUser)
        let record = try sut.addDrink(
            to: session,
            type: .beer,
            volumeML: 500
        )

        XCTAssertEqual(record.drinkType, .beer)
        XCTAssertEqual(record.volumeMl, 500)
        XCTAssertEqual(session.drinkRecords.count, 1)
        XCTAssertGreaterThan(session.totalPureAlcoholMl, 0)
    }

    func test_addDrink_customAbv() throws {
        let session = sut.startSession(user: testUser)
        let record = try sut.addDrink(
            to: session,
            type: .custom,
            volumeML: 200,
            abv: 15
        )
        XCTAssertEqual(record.abv, 15)
    }

    func test_addDrink_defaultAbv() throws {
        let session = sut.startSession(user: testUser)
        let record = try sut.addDrink(
            to: session,
            type: .baijiu,
            volumeML: 100
        )
        XCTAssertEqual(record.abv, DrinkType.baijiu.defaultAbv)
    }

    func test_addDrink_zeroVolume_throws() throws {
        let session = sut.startSession(user: testUser)
        XCTAssertThrowsError(try sut.addDrink(to: session, type: .beer, volumeML: 0)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_addDrink_negativeVolume_throws() throws {
        let session = sut.startSession(user: testUser)
        XCTAssertThrowsError(try sut.addDrink(to: session, type: .beer, volumeML: -100)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_addDrink_invalidAbv_throws() throws {
        let session = sut.startSession(user: testUser)
        XCTAssertThrowsError(try sut.addDrink(to: session, type: .custom, volumeML: 100, abv: -5)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_addDrink_abvOver100_throws() throws {
        let session = sut.startSession(user: testUser)
        XCTAssertThrowsError(try sut.addDrink(to: session, type: .custom, volumeML: 100, abv: 150)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_addDrink_toCompletedSession_throws() throws {
        let session = sut.startSession(user: testUser)
        _ = try sut.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sut.endSession(session)

        XCTAssertThrowsError(try sut.addDrink(to: session, type: .beer, volumeML: 500)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_addDrinks_batch() throws {
        let session = sut.startSession(user: testUser)
        let entries: [(type: DrinkType, volumeML: Double, abv: Double?)] = [
            (.beer, 500, nil),
            (.wine, 150, nil),
            (.baijiu, 50, nil),
        ]
        let records = try sut.addDrinks(to: session, entries: entries)

        XCTAssertEqual(records.count, 3)
        XCTAssertEqual(session.drinkRecords.count, 3)
    }

    // MARK: - 删除饮品

    func test_removeDrink_success() throws {
        let session = sut.startSession(user: testUser)
        let record = try sut.addDrink(to: session, type: .beer, volumeML: 500)
        let beforeCount = session.drinkRecords.count
        let beforeTotal = session.totalPureAlcoholMl

        try sut.removeDrink(record, from: session)

        XCTAssertEqual(session.drinkRecords.count, beforeCount - 1)
        XCTAssertLessThan(session.totalPureAlcoholMl, beforeTotal)
    }

    func test_removeDrink_notFound_throws() throws {
        let session = sut.startSession(user: testUser)
        let orphanRecord = DrinkRecord(drinkType: .beer, volumeMl: 500)
        XCTAssertThrowsError(try sut.removeDrink(orphanRecord, from: session)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_removeDrink_fromCompletedSession_throws() throws {
        let session = sut.startSession(user: testUser)
        let record = try sut.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sut.endSession(session)

        XCTAssertThrowsError(try sut.removeDrink(record, from: session)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    // MARK: - 会话结算

    func test_endSession_success() throws {
        let session = sut.startSession(user: testUser)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)

        let result = try sut.endSession(session)

        XCTAssertTrue(session.isCompleted)
        XCTAssertNotNil(session.endTime)
        XCTAssertNotNil(session.bacResult)
        XCTAssertEqual(session.bacResult?.id, result.id)
        XCTAssertGreaterThan(result.bacPercent, 0)
        XCTAssertGreaterThan(result.toleranceScore, 0)
        XCTAssertFalse(result.legalDrivingStatus.isEmpty)
        XCTAssertFalse(result.physicalEffects.isEmpty)
    }

    func test_endSession_noDrinks_throws() throws {
        let session = sut.startSession(user: testUser)
        XCTAssertThrowsError(try sut.endSession(session)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_endSession_noUser_throws() throws {
        let session = sut.startSession(user: nil)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)
        XCTAssertThrowsError(try sut.endSession(session)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_endSession_invalidWeight_throws() throws {
        let badUser = try userManager.createUser(nickname: "轻用户", weightKg: 0.1)
        let session = sut.startSession(user: badUser)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)
        XCTAssertThrowsError(try sut.endSession(session)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_endSession_alreadyEnded_throws() throws {
        let session = sut.startSession(user: testUser)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sut.endSession(session)

        XCTAssertThrowsError(try sut.endSession(session)) { error in
            XCTAssertTrue(error is SessionError)
        }
    }

    func test_endSession_multipleDrinks() throws {
        let session = sut.startSession(user: testUser)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)
        try sut.addDrink(to: session, type: .wine, volumeML: 150)

        let result = try sut.endSession(session)
        XCTAssertGreaterThan(result.totalAlcoholGrams, 0)
        XCTAssertGreaterThan(result.elapsedHours, 0)
    }

    // MARK: - 查询

    func test_fetchSessions() throws {
        let session1 = sut.startSession(user: testUser)
        try sut.addDrink(to: session1, type: .beer, volumeML: 500)
        _ = try sut.endSession(session1)

        let session2 = sut.startSession(user: testUser)
        try sut.addDrink(to: session2, type: .wine, volumeML: 150)
        _ = try sut.endSession(session2)

        let sessions = sut.fetchSessions(for: testUser)
        XCTAssertEqual(sessions.count, 2)
        // 按时间倒序
        XCTAssertGreaterThan(sessions[0].startTime, sessions[1].startTime)
    }

    func test_fetchActiveSession() throws {
        let active = sut.startSession(user: testUser)
        try sut.addDrink(to: active, type: .beer, volumeML: 500)

        let fetched = sut.fetchActiveSession(for: testUser)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, active.id)
    }

    func test_fetchActiveSession_noneActive_returnsNil() throws {
        let session = sut.startSession(user: testUser)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sut.endSession(session)

        XCTAssertNil(sut.fetchActiveSession(for: testUser))
    }

    func test_deleteSession() throws {
        let session = sut.startSession(user: testUser)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)

        try sut.deleteSession(session)
        let sessions = sut.fetchSessions(for: testUser)
        XCTAssertTrue(sessions.isEmpty)
    }

    // MARK: - 实时计算

    func test_calculateLiveBAC() throws {
        let session = sut.startSession(user: testUser)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)

        let liveBAC = sut.calculateLiveBAC(for: session)
        XCTAssertNotNil(liveBAC)
        XCTAssertGreaterThan(liveBAC!, 0)
    }

    func test_calculateLiveBAC_noDrinks() {
        let session = sut.startSession(user: testUser)
        let liveBAC = sut.calculateLiveBAC(for: session)
        XCTAssertEqual(liveBAC, 0)
    }

    func test_calculateLiveBAC_noUser() throws {
        let session = sut.startSession(user: nil)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)
        XCTAssertNil(sut.calculateLiveBAC(for: session))
    }

    // MARK: - 会话摘要

    func test_generateSummary_completed() throws {
        let session = sut.startSession(user: testUser)
        try sut.addDrink(to: session, type: .beer, volumeML: 500)
        _ = try sut.endSession(session)

        let summary = sut.generateSummary(for: session)
        XCTAssertTrue(summary.contains("会话摘要"))
        XCTAssertTrue(summary.contains("BAC"))
        XCTAssertTrue(summary.contains("等级"))
    }

    func test_generateSummary_inProgress() {
        let session = sut.startSession(user: testUser)
        try? sut.addDrink(to: session, type: .beer, volumeML: 500)

        let summary = sut.generateSummary(for: session)
        XCTAssertTrue(summary.contains("未完成") || summary.contains("进行中"))
    }

    func test_generateSummary_empty() {
        let session = sut.startSession(user: testUser)
        let summary = sut.generateSummary(for: session)
        XCTAssertTrue(summary.contains("未完成") || summary.contains("进行中"))
    }
}

// MARK: - BACCalculator 区域感知测试

/// BACCalculator 区域感知功能补充测试
final class BACCalculator_RegionTests: XCTestCase {

    func test_drivingAdvice_regionAware_cn() {
        let advice = BACCalculator.drivingAdvice(bac: 0.03, region: .cn)
        XCTAssertTrue(advice.contains("中国") || advice.contains("大陆"))
    }

    func test_drivingAdvice_regionAware_us() {
        let advice = BACCalculator.drivingAdvice(bac: 0.09, region: .us)
        XCTAssertTrue(advice.contains("美国"))
    }

    func test_drivingAdvice_regionAware_eu() {
        let advice = BACCalculator.drivingAdvice(bac: 0.06, region: .eu)
        XCTAssertTrue(advice.contains("欧盟"))
    }

    func test_drivingAdvice_deprecated_stillWorks() {
        // 废弃方法仍应正常工作
        let advice = BACCalculator.drivingAdvice(bac: 0.01)
        XCTAssertTrue(advice.contains("可以驾驶"))
    }

    func test_getSafeDrinkingGuideline_male() {
        let guideline = BACCalculator.getSafeDrinkingGuideline(isMale: true)
        XCTAssertEqual(guideline.maxUnits, 4.0)
        XCTAssertTrue(guideline.advice.contains("男性"))
    }

    func test_getSafeDrinkingGuideline_female() {
        let guideline = BACCalculator.getSafeDrinkingGuideline(isMale: false)
        XCTAssertEqual(guideline.maxUnits, 2.5)
        XCTAssertTrue(guideline.advice.contains("女性"))
    }

    func test_calculateStandardDrinks_beer() {
        let units = BACCalculator.calculateStandardDrinks(volumeML: 500, alcoholPercent: 5)
        // 500 * 0.05 * 0.789 / 10 = 1.9725
        XCTAssertEqual(units, 1.9725, accuracy: 0.001)
    }

    func test_formatBAC_mgPer100mL() {
        let formatted = BACCalculator.formatBAC(0.08, style: .mgPer100mL)
        XCTAssertEqual(formatted, "80 mg/100mL")
    }

    func test_estimatedSoberDate_future() {
        let date = BACCalculator.estimatedSoberDate(currentBAC: 0.08)
        XCTAssertGreaterThan(date, Date())
    }

    func test_estimatedSoberDate_zeroBAC_now() {
        let date = BACCalculator.estimatedSoberDate(currentBAC: 0.0)
        // 应该接近当前时间（允许小误差）
        XCTAssertLessThan(date.timeIntervalSinceNow, 1)
    }
}

// MARK: - SessionError Tests

/// SessionError 错误描述测试
final class SessionErrorTests: XCTestCase {

    func test_allErrors_haveDescriptions() {
        let errors: [SessionError] = [
            .sessionClosed,
            .alreadyEnded,
            .noDrinksRecorded,
            .noUserAssociated,
            .invalidUserWeight,
            .invalidVolume,
            .invalidAlcoholPercent,
            .recordNotFound,
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func test_errorDescriptions_areChinese() {
        let error = SessionError.sessionClosed
        XCTAssertTrue(error.errorDescription!.contains("会话"))
    }
}

// MARK: - UserError Tests

/// UserError 错误描述测试
final class UserErrorTests: XCTestCase {

    func test_allErrors_haveDescriptions() {
        let errors: [UserError] = [
            .invalidWeight,
            .invalidBirthYear,
            .emptyNickname,
            .userAlreadyExists(existing: User(nickname: "测试")),
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
