import SwiftUI
import SwiftData
import CoreKit
import GameEngine
import RoadBingo
import WouldYouRather
import Trivia
import Charades
import DesignSystem

@main
struct MileQuestApp: App {
    private let container: ModelContainer
    @State private var themeManager = ThemeManager()

    init() {
        let fileManager = FileManager.default
        let supportDir = URL.applicationSupportDirectory
        try? fileManager.createDirectory(at: supportDir, withIntermediateDirectories: true)
        let storeURL = supportDir.appending(path: "MileQuest.store")

        // UI tests pass -uitest-reset for a clean first launch; the relaunch
        // inside the test omits it, proving on-disk persistence.
        if CommandLine.arguments.contains("-uitest-reset") {
            for suffix in ["", "-shm", "-wal"] {
                try? fileManager.removeItem(at: supportDir.appending(path: "MileQuest.store\(suffix)"))
            }
        }

        do {
            container = try CoreSchema.container(at: storeURL)
        } catch {
            // Corrupt store fallback: an in-memory container keeps the app
            // usable; trip history is unavailable this launch.
            container = (try? CoreSchema.container(inMemory: true))!
        }

        MainActor.assumeIsolated {
            GameRegistry.shared.register(BingoGame.roadBingo())
            GameRegistry.shared.register(BingoGame.cabinBingo())
            GameRegistry.shared.register(BingoGame.trainBingo())
            GameRegistry.shared.register(WouldYouRatherGame())
            GameRegistry.shared.register(TriviaGame())
            GameRegistry.shared.register(CharadesGame())
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
