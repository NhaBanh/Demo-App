import Foundation

struct SellSyncSummaryLoader {
    let sellRepository: SellRepository
    let syncRepository: SyncRepository

    func load() async throws -> (sell: SellSummary, sync: SyncSummary) {
        async let sellItemCount = sellRepository.totalCount()
        async let pendingSyncCount = syncRepository.pendingSyncCount()

        return (
            sell: SellSummary(totalSellItems: try await sellItemCount),
            sync: SyncSummary(pendingCount: try await pendingSyncCount)
        )
    }
}
