import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var counts = DashboardCounts(toCall: 0, toBuy: 0, toSell: 0, pendingSync: 0)
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadDashboardCounts: LoadDashboardCountsUseCase

    init(loadDashboardCounts: LoadDashboardCountsUseCase) {
        self.loadDashboardCounts = loadDashboardCounts
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            counts = try await loadDashboardCounts.execute()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
