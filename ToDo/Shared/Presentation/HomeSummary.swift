import Foundation

struct HomeSummary: Equatable {
    var call = CallSummary()
    var buy = BuySummary()
    var sell = SellSummary()
    var sync = SyncSummary()
}

struct CallSummary: Equatable {
    var hotCount = 0
    var warmCount = 0
    var coldCount = 0
}

struct BuySummary: Equatable {
    var availableCount = 0
    var outOfStockCount = 0
    var outOfCatalogCount = 0
    var wishlistCount = 0
}

struct SellSummary: Equatable {
    var totalSellItems = 0
}

struct SyncSummary: Equatable {
    var pendingCount = 0
    var sessionSuccessCount = 0
}
