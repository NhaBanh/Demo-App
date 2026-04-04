import Foundation

struct PersonToCall: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let phoneNumbers: [String]
    let company: String
    let priority: CallPriority
    let lastContactedAt: Date?
    let notes: String
    let preferredContactTime: Date?
    let email: String?
}

enum CallPriority: String, CaseIterable, Codable {
    case hot
    case warm
    case cold
}
