import Foundation
import SwiftData

// MARK: - SwiftData 共享容器
/// 提供全局 ModelContainer，供 ViewModel init 中提前获�?ModelContext
enum DataStack {
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
