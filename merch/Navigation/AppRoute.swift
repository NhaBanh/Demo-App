import Foundation

// MARK: - App Routes

/// Defines all possible navigation routes in the app
enum AppRoute: Hashable {
    // Home & Products
    case home
    case productDetail(Product)

    // Cart
    case cart

    // Settings
    case settings
    case languageSettings

    // Profile
    case profile

    // Error Demo (for testing)
    case errorDemo
}

// MARK: - Route Extensions

extension AppRoute {
    /// Human-readable name for analytics/debugging
    var name: String {
        switch self {
        case .home:
            return "Home"
        case .productDetail:
            return "Product Detail"
        case .cart:
            return "Cart"
        case .settings:
            return "Settings"
        case .languageSettings:
            return "Language Settings"
        case .profile:
            return "Profile"
        case .errorDemo:
            return "Error Demo"
        }
    }

    /// Whether this route should be tracked in analytics
    var shouldTrack: Bool {
        switch self {
        case .errorDemo:
            return false // Don't track demo screens
        default:
            return true
        }
    }
}
