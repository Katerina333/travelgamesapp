import SwiftUI
import SwiftData
import CoreKit
import DesignSystem

@main
struct MileQuestApp: App {
    private let container: ModelContainer
    @State private var themeManager = ThemeManager()

    init() {
        do {
            container = try CoreSchema.container()
        } catch {
            // Corrupt store fallback: an in-memory container keeps the app
            // usable; trip history is unavailable this launch.
            container = (try? CoreSchema.container(inMemory: true))!
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(themeManager)
        }
        .modelContainer(container)
    }
}
