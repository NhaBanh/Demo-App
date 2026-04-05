import Foundation

struct QueuedSellOperation: Identifiable, Equatable, Hashable {
    enum OperationType: String, Codable, CaseIterable {
        case create
        case update
        case delete

        nonisolated init?(databaseValue: String) {
            switch databaseValue {
            case Self.create.rawValue:
                self = .create
            case Self.update.rawValue:
                self = .update
            case Self.delete.rawValue:
                self = .delete
            case "sellOne", "markSold":
                self = .update
            default:
                return nil
            }
        }
    }

    let id: UUID
    let itemID: UUID
    let type: OperationType
    let payload: SellItem?
    let queuedAt: Date
    let retryCount: Int
}
