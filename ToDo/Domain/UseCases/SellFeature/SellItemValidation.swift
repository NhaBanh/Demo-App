import Foundation

enum SellItemValidation {
    static let maxNameLength = 120
    static let maxNotesLength = 1_000
    static let maxQuantity = 9_999
    static let maxPrice: Decimal = 999_999.99

    static func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedNotes(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func validate(name: String, askingPrice: Decimal, quantity: Int, notes: String) throws {
        guard !name.isEmpty else {
            throw AppError.validation("Name is required.")
        }
        guard name.count <= maxNameLength else {
            throw AppError.validation("Name must be 120 characters or fewer.")
        }
        guard askingPrice > 0 else {
            throw AppError.validation("Price must be greater than zero.")
        }
        guard askingPrice <= maxPrice else {
            throw AppError.validation("Price is too large.")
        }
        guard hasAtMostTwoDecimalPlaces(askingPrice) else {
            throw AppError.validation("Price must have at most 2 decimal places.")
        }
        guard quantity > 0 else {
            throw AppError.validation("Quantity must be greater than zero.")
        }
        guard quantity <= maxQuantity else {
            throw AppError.validation("Quantity must be 9,999 or fewer.")
        }
        guard notes.count <= maxNotesLength else {
            throw AppError.validation("Notes must be 1,000 characters or fewer.")
        }
    }

    static func validateUpdate(current: SellItem, updated: SellItem) throws {
        try validate(
            name: normalizedName(updated.name),
            askingPrice: updated.askingPrice,
            quantity: updated.quantity,
            notes: normalizedNotes(updated.notes)
        )

        if current.isSold && (
            current.name != updated.name
                || current.askingPrice != updated.askingPrice
                || current.quantity != updated.quantity
        ) {
            throw AppError.validation("Sold items cannot change name, price, or quantity.")
        }
    }

    private static func hasAtMostTwoDecimalPlaces(_ value: Decimal) -> Bool {
        var decimal = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimal, 2, .plain)
        return rounded == value
    }
}
