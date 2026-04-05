import BackgroundTasks
import SwiftData
import SwiftUI

@main
struct ToDoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appContainer: AppContainer
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([WishlistSwiftDataModel.self])
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
            let container = AppContainer(modelContainer: modelContainer)
            container.sellSyncBackgroundTaskManager.register()
            container.sellSyncBackgroundTaskManager.scheduleNextRun()
            _appContainer = State(initialValue: container)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: appContainer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                appContainer.sellSyncBackgroundTaskManager.scheduleNextRun()
            }
        }
        .modelContainer(modelContainer)
    }
}
