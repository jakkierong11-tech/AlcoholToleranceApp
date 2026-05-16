import Foundation
import SwiftData

// MARK: - SwiftData 共享容器

/// 单例共享容器，App 启动时创建，包含所有 Model 类型
@MainActor
final class DataStack: @unchecked Sendable {
    static let shared = DataStack()

    let container: ModelContainer

    private init() {
        do {
            container = try ModelContainer(
                for: User.self,
                DrinkSession.self,
                DrinkRecord.self,
                BACResult.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
