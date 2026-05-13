import Foundation
import SwiftUI
import SwiftData

// MARK: - 用户档案 ViewModel（适配总管 User + UserManager）
@MainActor
final class ProfileVM: ObservableObject {
    @Published var user: User
    @Published var showSaveConfirmation = false

    private let userManager: UserManager

    init(modelContext: ModelContext) {
        self.userManager = UserManager(modelContext: modelContext)
        self.user = userManager.fetchOrCreateUser()
    }

    // MARK: - 更新

    func updateGender(isMale: Bool) {
        user.isMale = isMale
        user.lastActiveAt = Date()
        try? userManager.updateProfile(user: user, isMale: isMale)
    }

    func updateWeight(_ kg: Double) {
        user.weightKg = max(10, min(300, kg))
        user.lastActiveAt = Date()
        try? userManager.updateProfile(user: user, weightKg: user.weightKg)
    }

    func updateNickname(_ name: String) {
        user.nickname = name
        user.lastActiveAt = Date()
        try? userManager.updateProfile(user: user, nickname: name)
    }

    func saveProfile() {
        try? userManager.updateProfile(user: user)
        showSaveConfirmation = true
    }

    /// View 层兼容方法
    func loadProfile() {
        user = userManager.fetchOrCreateUser()
    }

    func resetAllData() {
        user = userManager.fetchOrCreateUser()
        showSaveConfirmation = false
    }

    /// 酒量称号（基于 User.highestScore）
    var toleranceTitle: String {
        user.title
    }

    /// View 层兼容别名
    var title: String { toleranceTitle }
    var highestScore: Double { user.highestScore }
    var totalSessions: Int { user.totalTests }

    /// Widmark 系数
    var widmarkFactor: Double {
        user.widmarkFactor
    }

    /// 性别中文
    var genderLabel: String {
        user.isMale ? "男性" : "女性"
    }
}
