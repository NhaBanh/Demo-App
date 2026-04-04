import Foundation

struct PendingSale: Identifiable, Equatable, Hashable {
    let id: UUID
    let itemID: UUID
    let itemName: String
    let queuedAt: Date
}
