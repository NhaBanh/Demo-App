import Foundation

struct LoadDashboardCountsUseCase {
    let toCallRepository: ToCallRepository
    let buyRepository: BuyRepository
    let sellRepository: ToSellRepository
    let sellSyncQueueRepository: SellSyncQueueRepository

    func execute() async throws -> DashboardCounts {
        async let toCall = toCallRepository.totalCount()
        async let toBuy = buyRepository.totalCount()
        async let toSell = sellRepository.totalCount()
        async let pending = sellSyncQueueRepository.pendingCount()

        return try await DashboardCounts(
            toCall: toCall,
            toBuy: toBuy,
            toSell: toSell,
            pendingSync: pending
        )
    }
}
