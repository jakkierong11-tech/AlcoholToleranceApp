import SwiftUI
import SwiftData
@main
struct AlcoholToleranceApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [NeonColors.background, NeonColors.cardBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    DashboardView(vm: DashboardVM(modelContext: DataStack.shared.container.mainContext))
                        .preferredColorScheme(.dark)
                }
            }
        }
    }
}
