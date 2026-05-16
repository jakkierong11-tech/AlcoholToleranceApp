import XCTest
import SwiftData
@testable import AlcoholToleranceApp

// MARK: - BACCalculator 性能测试

/// BACCalculator 性能基准测试
final class BACCalculatorPerformanceTests: XCTestCase {

    // MARK: - 峰值 BAC 计算性能

    func test_calculatePeakBAC_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.calculatePeakBAC(
                    weightKg: 70.0,
                    isMale: true,
                    volumeML: 500.0,
                    alcoholPercent: 5.0,
                    isCarbonated: false,
                    isEmptyStomach: false
                )
            }
        }
    }

    // MARK: - 累积 BAC 计算性能

    func test_calculateCumulativeBAC_performance() {
        let drinks: [(volumeML: Double, alcoholPercent: Double, hoursAgo: Double, isCarbonated: Bool, isEmptyStomach: Bool)] = [
            (500, 5.0, 0.5, false, false),
            (300, 12.0, 1.0, false, false),
            (100, 52.0, 2.0, false, false),
            (200, 15.0, 0.0, true, true),
        ]

        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.calculateCumulativeBAC(
                    weightKg: 70.0,
                    isMale: true,
                    drinks: drinks,
                    metabolismRate: 0.015
                )
            }
        }
    }

    // MARK: - 大量饮品累积 BAC 性能

    func test_calculateCumulativeBAC_largeDrinkList_performance() {
        var drinks: [(volumeML: Double, alcoholPercent: Double, hoursAgo: Double, isCarbonated: Bool, isEmptyStomach: Bool)] = []
        for i in 0..<100 {
            drinks.append((500, 5.0, Double(i) * 0.1, i % 2 == 0, i % 3 == 0))
        }

        measure {
            for _ in 0..<1000 {
                _ = BACCalculator.calculateCumulativeBAC(
                    weightKg: 70.0,
                    isMale: true,
                    drinks: drinks,
                    metabolismRate: 0.015
                )
            }
        }
    }

    // MARK: - BAC 等级查询性能

    func test_getBACLevel_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.getBACLevel(bacPercent: 0.085)
            }
        }
    }

    // MARK: - 评分计算性能

    func test_calculateSessionScore_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.calculateSessionScore(
                    bacPercent: 0.15,
                    totalAlcoholGrams: 50.0,
                    weightKg: 70.0
                )
            }
        }
    }

    func test_calculateToleranceScore_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.calculateToleranceScore(
                    sessionAvg: 60.0,
                    testAvg: 70.0,
                    totalSessions: 30
                )
            }
        }
    }

    // MARK: - 格式化性能

    func test_formatBAC_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.formatBAC(0.085, style: .percent)
                _ = BACCalculator.formatBAC(0.085, style: .mgPer100mL)
            }
        }
    }

    func test_formatSoberTime_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.formatSoberTime(hours: 5.5)
            }
        }
    }

    // MARK: - 法律阈值判断性能

    func test_isOverLegalLimit_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.isOverLegalLimit(bac: 0.025, limit: 0.02)
            }
        }
    }

    // MARK: - 醒酒时间计算性能

    func test_calculateSoberTime_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.calculateSoberTime(currentBAC: 0.08, metabolismRate: 0.015)
            }
        }
    }

    func test_calculateBACAfterTime_performance() {
        measure {
            for _ in 0..<10000 {
                _ = BACCalculator.calculateBACAfterTime(
                    initialBAC: 0.08,
                    hoursPassed: 3.0,
                    metabolismRate: 0.015
                )
            }
        }
    }
}

// MARK: - 内存压力测试

/// 内存使用压力测试
@MainActor
final class MemoryPressureTests: XCTestCase {

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        let schema = Schema([User.self, DrinkSession.self, DrinkRecord.self, BACResult.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
        } catch {
            XCTFail("创建内存 ModelContainer 失败: \(error)")
        }
    }

    override func tearDown() {
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    func test_massSessionCreation() {
        let userManager = UserManager(modelContext: modelContext)
        let sessionManager = DrinkSessionManager(modelContext: modelContext)
        let user = userManager.fetchOrCreateUser()

        measure {
            for _ in 0..<100 {
                let session = sessionManager.startSession(user: user)
                for _ in 0..<10 {
                    try? sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
                }
                _ = try? sessionManager.endSession(session)
            }
        }

        let sessions = sessionManager.fetchSessions(for: user, limit: 1000)
        XCTAssertEqual(sessions.count, 100)
    }

    func test_largeDrinkRecordList() {
        let userManager = UserManager(modelContext: modelContext)
        let sessionManager = DrinkSessionManager(modelContext: modelContext)
        let user = userManager.fetchOrCreateUser()
        let session = sessionManager.startSession(user: user)

        measure {
            for _ in 0..<1000 {
                try? sessionManager.addDrink(to: session, type: .beer, volumeML: 500)
            }
        }

        XCTAssertEqual(session.drinkRecords.count, 1000)
    }
}
