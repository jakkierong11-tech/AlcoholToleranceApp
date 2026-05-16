import XCTest
import SwiftData
@testable import AlcoholToleranceApp

// MARK: - DashboardVM Tests

@MainActor
final class DashboardVMTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var sut: DashboardVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        sut = DashboardVM(modelContext: modelContainer.mainContext)
    }

    override func tearDown() {
        sut = nil; modelContainer = nil; super.tearDown()
    }

    func test_initialState() {
        XCTAssertNotNil(sut.user)
        XCTAssertEqual(sut.user.nickname, "酒友")
        XCTAssertEqual(sut.currentBAC, 0)
        XCTAssertEqual(sut.bacLevel, .sober)
    }

    func test_nickname() { XCTAssertFalse(sut.nickname.isEmpty) }
    func test_genderLabel() { XCTAssertTrue(sut.genderLabel.contains("男") || sut.genderLabel.contains("女")) }
    func test_weightKg() { XCTAssertGreaterThan(sut.weightKg, 0) }
    func test_bacLevel_noBAC_isSober() { XCTAssertEqual(sut.bacLevel, .sober) }
    func test_sessionScore_initial() { XCTAssertEqual(sut.sessionScore, 0) }
    func test_refresh_doesNotCrash() { sut.refresh(); XCTAssertNotNil(sut.user) }
    func test_hasTestedToday_initialFalse() { XCTAssertFalse(sut.hasTestedToday) }
    func test_canStartTest() { XCTAssertTrue(sut.canStartTest) }
    func test_hasHistory_initialFalse() { XCTAssertFalse(sut.hasHistory) }
    func test_safeGuideline_notEmpty() { XCTAssertFalse(sut.safeGuideline.isEmpty) }
    func test_toleranceTitle() { XCTAssertFalse(sut.toleranceTitle.isEmpty) }
}

// MARK: - DrinkLoggerVM Tests

@MainActor
final class DrinkLoggerVMTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var sut: DrinkLoggerVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        sut = DrinkLoggerVM(modelContext: modelContainer.mainContext)
    }

    override func tearDown() {
        sut = nil; modelContainer = nil; super.tearDown()
    }

    func test_initialState() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.selectedDrinkType, .beer)
        XCTAssertEqual(sut.volumeMl, 500)
        XCTAssertEqual(sut.legalRegion, .cn)
    }

    func test_setDrinkType() {
        sut.setDrinkType(.baijiu)
        XCTAssertEqual(sut.selectedDrinkType, .baijiu)
    }

    func test_onDrinkTypeChanged_updatesDefaults() {
        sut.setDrinkType(.wine)
        XCTAssertEqual(sut.volumeMl, DrinkType.wine.typicalVolumeMl)
    }

    func test_estimateSingleDrinkBAC() {
        sut.volumeMl = 500; sut.abv = 5.0
        sut.estimateSingleDrinkBAC()
        XCTAssertNotNil(sut.estimatedBAC)
    }

    func test_standardDrinks_initial() {
        sut.volumeMl = 500; sut.abv = 5.0
        sut.estimateSingleDrinkBAC()
        XCTAssertGreaterThan(sut.standardDrinks, 0)
    }

    func test_refreshUser() { sut.refreshUser() }
}

// MARK: - ProfileVM Tests

@MainActor
final class ProfileVMTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var sut: ProfileVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        sut = ProfileVM(modelContext: modelContainer.mainContext)
    }

    override func tearDown() {
        sut = nil; modelContainer = nil; super.tearDown()
    }

    func test_initialState() {
        XCTAssertNotNil(sut.user)
        XCTAssertEqual(sut.user.nickname, "酒友")
    }

    func test_updateNickname() {
        sut.updateNickname("老王")
        XCTAssertEqual(sut.user.nickname, "老王")
    }

    func test_updateWeight() {
        sut.updateWeight(80)
        XCTAssertEqual(sut.user.weightKg, 80)
    }

    func test_updateGender() {
        let original = sut.user.isMale
        sut.updateGender(isMale: !original)
        XCTAssertEqual(sut.user.isMale, !original)
    }

    func test_title() { XCTAssertFalse(sut.title.isEmpty) }
    func test_highestScore() { XCTAssertGreaterThanOrEqual(sut.highestScore, 0) }
    func test_totalSessions() { XCTAssertGreaterThanOrEqual(sut.totalSessions, 0) }
    func test_genderLabel() { XCTAssertTrue(["男性", "女性"].contains(sut.genderLabel)) }
    func test_widmarkFactor() { XCTAssertTrue(sut.widmarkFactor == 0.68 || sut.widmarkFactor == 0.55) }
    func test_loadProfile() { sut.loadProfile(); XCTAssertNotNil(sut.user) }
    func test_saveProfile() { sut.saveProfile(); XCTAssertFalse(sut.showSaveConfirmation) }
}

// MARK: - SettingsVM Tests

@MainActor
final class SettingsVMTests: XCTestCase {
    private var sut: SettingsVM!

    override func setUp() { super.setUp(); sut = SettingsVM() }
    override func tearDown() { sut.resetToDefaults(); sut = nil; super.tearDown() }

    func test_initialRegion_isCN() { XCTAssertEqual(sut.selectedRegion, .cn) }
    func test_changeRegion() { sut.selectedRegion = .us; XCTAssertEqual(sut.selectedRegion, .us) }
    func test_initialMetabolismRate() { XCTAssertEqual(sut.metabolismRate, 0.015, accuracy: 0.001) }
    func test_changeMetabolismRate() { sut.metabolismRate = 0.02; XCTAssertEqual(sut.metabolismRate, 0.02, accuracy: 0.001) }
    func test_drivingAdvice() { XCTAssertFalse(sut.drivingAdvice(for: 0.03).isEmpty) }
    func test_effectiveDrinkDriveLimit() { XCTAssertGreaterThan(sut.effectiveDrinkDriveLimit, 0) }
    func test_effectiveDuiLimit() { XCTAssertGreaterThan(sut.effectiveDuiLimit, 0) }
    func test_resetToDefaults() {
        sut.selectedRegion = .us; sut.metabolismRate = 0.02
        sut.resetToDefaults()
        XCTAssertEqual(sut.selectedRegion, .cn)
        XCTAssertEqual(sut.metabolismRate, 0.015, accuracy: 0.001)
    }
}

// MARK: - HistoryVM Tests

@MainActor
final class HistoryVMTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var sessionManager: DrinkSessionManager!
    private var sut: HistoryVM!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        sessionManager = DrinkSessionManager(modelContext: modelContainer.mainContext)
        sut = HistoryVM(modelContext: modelContainer.mainContext)
    }

    override func tearDown() {
        sut = nil; sessionManager = nil; modelContainer = nil; super.tearDown()
    }

    func test_initialState() {
        XCTAssertTrue(sut.completedSessions.isEmpty)
        XCTAssertTrue(sut.results.isEmpty)
        XCTAssertNil(sut.selectedResult)
        XCTAssertEqual(sut.filter, .all)
    }

    func test_loadAll() {
        sut.loadAll()
        // 不崩溃即可
    }

    func test_filter_all() {
        sut.filter = .all
        XCTAssertEqual(sut.filter, .all)
    }

    func test_filter_today() {
        sut.filter = .today
        XCTAssertEqual(sut.filter, .today)
    }

    func test_isLoading_initial() { XCTAssertFalse(sut.isLoading) }
}
