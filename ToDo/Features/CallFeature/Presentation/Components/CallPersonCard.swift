import SwiftUI

struct CallPersonCard: View {
    let person: PersonToCall

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(person.name).font(.headline)
            Text(person.company).foregroundStyle(.secondary)

            ForEach(Array(person.phoneNumbers.enumerated()), id: \.offset) { index, phoneNumber in
                Label(phoneNumber, systemImage: index == 0 ? "phone.fill" : "phone")
            }

            if let email = person.email {
                Label(email, systemImage: "envelope")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(person.priority.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.12), in: Capsule())

            if let lastContactedAt = person.lastContactedAt {
                Text("Last contacted: \(lastContactedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let preferredContactTime = person.preferredContactTime {
                Text("Preferred contact: \(preferredContactTime.formatted(date: .omitted, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !person.notes.isEmpty {
                Text(person.notes)
                    .font(.footnote)
            }
        }
        .padding(.vertical, 4)
    }
}
