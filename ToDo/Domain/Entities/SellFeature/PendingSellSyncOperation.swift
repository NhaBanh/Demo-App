import Foundation

struct PendingSellSyncOperation: Identifiable, Equatable, Hashable {
    enum OperationType: String, Codable, Hashable {
        case create
        case update
        case delete
        case markSold
    }

    let id: UUID
    let itemID: UUID
    let type: OperationType
    let payload: SellItem?
    let queuedAt: Date
    let retryCount: Int
}
