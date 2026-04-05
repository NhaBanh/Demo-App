import Foundation

struct RemotePersonToCallDTO: Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let phoneNumbers: [String]
    let company: String
    let priority: CallPriority
    let lastContactedAt: Date?
    let notes: String
    let preferredContactTime: Date?
    let email: String?

    func toDomain() -> PersonToCall {
        PersonToCall(
            id: id,
            name: name,
            phoneNumbers: phoneNumbers,
            company: company,
            priority: priority,
            lastContactedAt: lastContactedAt,
            notes: notes,
            preferredContactTime: preferredContactTime,
            email: email
        )
    }
}

struct RemoteToCallPageDTO: Equatable {
    let items: [RemotePersonToCallDTO]
    let page: Int
    let totalPages: Int
    let lastSyncedAt: Date
}
