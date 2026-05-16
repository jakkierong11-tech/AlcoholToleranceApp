import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - 测试会话 ViewModel（适配总管 BACCalculator + DrinkSessionManager）
@MainActor
final class TestSessionVM: ObservableObject {
    @Published var user: User
    @Published var session: DrinkSession?
    @Published var currentResult: BACResult?
    @Published var currentBACPercent: Double?
    @Published var currentLevel: String?
    @Published var timerText: String = "00:00"
    @Published var selectedDrinkType: DrinkType = .beer
    @Published var customVolumeMl: Double = 500
    @Published var customABV: Double = 5.0
    @Published var isEmptyStomach: Bool = false
    @Published var showWarning: Bool = false

    private let sessionManager: DrinkSessionManager
    private let userManager: UserManager
    private var timerCancellable: AnyCancellable?

    init(modelContext: ModelContext, user: User) {
        self.sessionManager = DrinkSessionManager(modelContext: modelContext)
        self.userManager = UserManager(modelContext: modelContext)
        self.user = user
    }

    deinit {
        timerCancellable?.cancel()
    }

    // MARK: - 测试流程

    func startTest(isEmptyStomach: Bool = false) {
        self.isEmptyStomach = isEmptyStomach
        session = sessionManager.startSession(user: user, isEmptyStomach: isEmptyStomach)
        startTimer()
    }

    func addDrink() {
        guard let session, !session.isCompleted else { return }

        let volume = customVolumeMl > 0 ? customVolumeMl : selectedDrinkType.typicalVolumeMl
        let abv = customABV > 0 ? customABV : selectedDrinkType.defaultAbv
        guard volume > 0, abv > 0, abv <= 100 else { return }

        do {
            try sessionManager.addDrink(
                to: session,
                type: selectedDrinkType,
                volumeML: volume,
                abv: abv
            )
            refreshLiveBAC()
        } catch {
            print("[TestSessionVM] 添加饮品失败: \(error)")
        }
    }

    func removeDrink(at index: Int) {
        guard let session, index < session.drinkRecords.count else { return }
        let record = session.drinkRecords[index]
        try? sessionManager.removeDrink(record, from: session)
        refreshLiveBAC()
    }

    /// 实时 BAC 刷新（饮杯中）
    private func refreshLiveBAC() {
        guard let session, !session.drinkRecords.isEmpty else {
            currentBACPercent = nil
            currentLevel = nil
            return
        }
        let bac = BACCalculator.calculateCumulativeBAC(
            weightKg: user.weightKg,
            isMale: user.isMale,
            drinks: session.drinkRecords
        )
        currentBACPercent = bac
        let info = BACCalculator.getBACLevel(bacPercent: bac)
        currentLevel = info.label
        showWarning = bac >= 0.05
    }

    func endTest() {
        guard let session else { return }
        do {
            let result = try sessionManager.endSession(
                session,
                isEmptyStomach: isEmptyStomach
            )
            stopTimer()
            currentResult = result
            userManager.updateUserScore(user: user, newScore: result.toleranceScore)
        } catch {
            print("[TestSessionVM] 结束会话失败: \(error)")
        }
    }

    func cancelTest() {
        guard let session else { return }
        try? sessionManager.deleteSession(session)
        self.session = nil
        stopTimer()
    }

    // MARK: - Timer
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func updateTimer() {
        guard let session else { return }
        let elapsed = Date().timeIntervalSince(session.startTime) / 3600.0
        let h = Int(elapsed)
        let m = Int((elapsed - Double(h)) * 60)
        let s = Int(((elapsed - Double(h)) * 60 - Double(m)) * 60)
        timerText = String(format: "%02d:%02d:%02d", h, m, s)

        if s == 0 { refreshLiveBAC() }
    }
}
