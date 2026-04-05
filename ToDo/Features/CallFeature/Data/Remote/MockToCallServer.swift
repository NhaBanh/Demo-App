import Foundation

actor MockToCallServer {
    private let transientFailureRate = 0.2
    private let people: [RemotePersonToCallDTO] = [
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000001"), name: "Ava Nguyen", phoneNumbers: ["090-111-2222", "028-7300-1122"], company: "Northern Labs", priority: .hot, lastContactedAt: .now.addingTimeInterval(-3_600), notes: "Asked for a product pricing callback this afternoon.", preferredContactTime: .now.addingTimeInterval(7_200), email: "ava.nguyen@northernlabs.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000002"), name: "Ben Carter", phoneNumbers: ["090-111-3333"], company: "Maple Works", priority: .warm, lastContactedAt: .now.addingTimeInterval(-86_400), notes: "Interested in volume discounts for the next quarter.", preferredContactTime: .now.addingTimeInterval(10_800), email: "ben.carter@mapleworks.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000003"), name: "Chloe Tran", phoneNumbers: ["090-111-4444", "090-222-4444"], company: "Eastline", priority: .hot, lastContactedAt: nil, notes: "New lead from the trade show. No previous conversation yet.", preferredContactTime: .now.addingTimeInterval(14_400), email: "chloe.tran@eastline.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000004"), name: "Daniel Lee", phoneNumbers: ["090-111-5555"], company: "Forge AI", priority: .cold, lastContactedAt: .now.addingTimeInterval(-172_800), notes: "Waiting to revisit once the current contract cycle ends.", preferredContactTime: nil, email: "daniel.lee@forgeai.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000005"), name: "Emma Pham", phoneNumbers: ["090-111-6666", "028-7300-6677"], company: "Oak Retail", priority: .warm, lastContactedAt: .now.addingTimeInterval(-43_200), notes: "Requested a callback after store opening hours.", preferredContactTime: .now.addingTimeInterval(18_000), email: "emma.pham@oakretail.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000006"), name: "Finn Ho", phoneNumbers: ["090-111-7777"], company: "Cargo Bee", priority: .cold, lastContactedAt: nil, notes: "Prospect list import. Needs initial qualification.", preferredContactTime: nil, email: nil),
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000007"), name: "Grace Vu", phoneNumbers: ["090-111-8888", "090-111-8899"], company: "Bright Supply", priority: .hot, lastContactedAt: .now.addingTimeInterval(-7_200), notes: "Follow up on the pending purchase order before end of day.", preferredContactTime: .now.addingTimeInterval(3_600), email: "grace.vu@brightsupply.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000008"), name: "Henry Do", phoneNumbers: ["090-111-9999"], company: "Horizon Tech", priority: .warm, lastContactedAt: .now.addingTimeInterval(-259_200), notes: "Needs a quick check-in on renewal timing.", preferredContactTime: .now.addingTimeInterval(21_600), email: "henry.do@horizontech.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-000000000009"), name: "Iris Chen", phoneNumbers: ["090-211-1001", "028-7101-1001"], company: "Cloud Finch", priority: .hot, lastContactedAt: .now.addingTimeInterval(-1_800), notes: "Waiting for a same-day callback about enterprise onboarding.", preferredContactTime: .now.addingTimeInterval(5_400), email: "iris.chen@cloudfinch.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-00000000000A"), name: "Jack Bui", phoneNumbers: ["090-211-1002"], company: "Riverstone", priority: .cold, lastContactedAt: .now.addingTimeInterval(-604_800), notes: "Paused until the new budget cycle starts next month.", preferredContactTime: nil, email: "jack.bui@riverstone.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-00000000000B"), name: "Kara Le", phoneNumbers: ["090-211-1003"], company: "Blue Harbor", priority: .warm, lastContactedAt: nil, notes: "Referred by an existing customer. Needs first discovery call.", preferredContactTime: .now.addingTimeInterval(25_200), email: "kara.le@blueharbor.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-00000000000C"), name: "Leo Tran", phoneNumbers: ["090-211-1004", "090-211-2004"], company: "Atlas Parts", priority: .hot, lastContactedAt: .now.addingTimeInterval(-14_400), notes: "Asked for confirmation on delivery lead times before noon tomorrow.", preferredContactTime: .now.addingTimeInterval(9_000), email: "leo.tran@atlasparts.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-00000000000D"), name: "Mina Vo", phoneNumbers: ["090-211-1005"], company: "Studio Cedar", priority: .warm, lastContactedAt: .now.addingTimeInterval(-95_000), notes: "Reviewing the proposal with operations this week.", preferredContactTime: .now.addingTimeInterval(28_800), email: "mina.vo@studiocedar.example"),
        .init(id: fixedUUID("00000000-0000-0000-0000-00000000000E"), name: "Noah Phan", phoneNumbers: ["090-211-1006"], company: "North Peak", priority: .cold, lastContactedAt: nil, notes: "No response yet from initial email outreach.", preferredContactTime: nil, email: nil),
        .init(id: fixedUUID("00000000-0000-0000-0000-00000000000F"), name: "Olivia Dang", phoneNumbers: ["090-211-1007", "028-7101-1007"], company: "Green Basket", priority: .hot, lastContactedAt: .now.addingTimeInterval(-10_800), notes: "Needs urgent price confirmation for a same-week order.", preferredContactTime: .now.addingTimeInterval(4_800), email: "olivia.dang@greenbasket.example"),
    ]

    func fetchPeople(page: Int, pageSize: Int, searchText: String?) async throws -> RemoteToCallPageDTO {
        try await Task.sleep(for: .milliseconds(250))

        if Int.random(in: 1...100) <= Int(transientFailureRate * 100) {
            throw AppError.transientNetwork("Temporary network issue while loading contacts.")
        }

        let normalizedSearchText = searchText?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let filteredPeople: [RemotePersonToCallDTO]
        if let normalizedSearchText, !normalizedSearchText.isEmpty {
            filteredPeople = people.filter { person in
                person.name.lowercased().contains(normalizedSearchText)
                    || person.company.lowercased().contains(normalizedSearchText)
                    || person.phoneNumbers.contains { $0.localizedCaseInsensitiveContains(normalizedSearchText) }
            }
        } else {
            filteredPeople = people
        }

        let totalPages = max(1, Int(ceil(Double(filteredPeople.count) / Double(pageSize))))
        let normalizedPage = min(max(page, 1), totalPages)
        let start = max(0, (normalizedPage - 1) * pageSize)
        let end = min(filteredPeople.count, start + pageSize)
        let pageItems = Array(filteredPeople[start..<end])

        return RemoteToCallPageDTO(
            items: pageItems,
            page: normalizedPage,
            totalPages: totalPages,
            lastSyncedAt: Date()
        )
    }

    func totalCount() -> Int {
        people.count
    }

    private static func fixedUUID(_ value: String) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            preconditionFailure("Invalid fixed UUID: \(value)")
        }
        return uuid
    }
}
