import Foundation
import SwiftData

// MARK: - SwiftData 共享容器
// [corrupted comment removed]
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
