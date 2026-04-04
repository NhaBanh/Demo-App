import SwiftData
import SwiftUI

@main
struct ToDoApp: App {
    @State private var appContainer: AppContainer
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([WishlistEntry.self])
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
            _appContainer = State(initialValue: AppContainer(modelContainer: modelContainer))
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: appContainer)
        }
        .modelContainer(modelContainer)
    }
}
