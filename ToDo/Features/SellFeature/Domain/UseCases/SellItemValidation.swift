import Foundation

enum SellItemValidation {
    static let maxTitleLength = 120
    static let maxDetailLength = 1_000
    static let maxQuantity = 9_999
    static let maxPrice: Decimal = 999_999.99

    static func normalizedTitle(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedDetail(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func validateCreate(title: String, askingPrice: Decimal, quantity: Int, detail: String) throws {
        try validateCommon(title: title, askingPrice: askingPrice, quantity: quantity, detail: detail)
        guard quantity > 0 else {
            throw AppError.validation("Quantity must be greater than zero.")
        }
    }

    static func validateUpdate(current: SellItem, updated: SellItem) throws {
        try validateCommon(
            title: normalizedTitle(updated.title),
            askingPrice: updated.askingPrice,
            quantity: updated.quantity,
            detail: normalizedDetail(updated.detail)
        )
        guard updated.quantity >= 0 else {
            throw AppError.validation("Quantity cannot be negative.")
        }
    }

    static func validateSell(amount: Int, availableQuantity: Int, status: SellItemStatus) throws {
        guard status == .active else {
            throw AppError.validation("Archived items cannot be sold.")
        }
        guard amount > 0 else {
            throw AppError.validation("Sold amount must be greater than zero.")
        }
        guard amount <= availableQuantity else {
            throw AppError.validation("Sold amount cannot exceed available quantity.")
        }
    }

    private static func validateCommon(title: String, askingPrice: Decimal, quantity: Int, detail: String) throws {
        guard !title.isEmpty else {
            throw AppError.validation("Title is required.")
        }
        guard title.count <= maxTitleLength else {
            throw AppError.validation("Title must be 120 characters or fewer.")
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
        guard quantity >= 0 else {
            throw AppError.validation("Quantity cannot be negative.")
        }
        guard quantity <= maxQuantity else {
            throw AppError.validation("Quantity must be 9,999 or fewer.")
        }
        guard detail.count <= maxDetailLength else {
            throw AppError.validation("Detail must be 1,000 characters or fewer.")
        }
    }

    private static func hasAtMostTwoDecimalPlaces(_ value: Decimal) -> Bool {
        var decimal = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimal, 2, .plain)
        return rounded == value
    }
}
