import Foundation
import SwiftData
@testable import ToDo

enum TestStoreHelpers {
    static func makeInMemoryWishlistContainer() throws -> ModelContainer {
        let schema = Schema([WishlistSwiftDataModel.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeSQLiteFilename(prefix: String) -> String {
        "\(prefix)-\(UUID().uuidString).sqlite"
    }

    static func removeSQLiteFile(named filename: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = documentsURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
