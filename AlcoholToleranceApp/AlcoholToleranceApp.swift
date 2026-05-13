import SwiftUI
import SwiftData
@main
struct AlcoholToleranceApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                LinearGradient(
                    colors: [NeonColors.background, NeonColors.cardBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                DashboardView(vm: DashboardVM(modelContext: ModelContext(DataStack.shared.container)))
                    .preferredColorScheme(.dark)
            }
        }
    }
}
