import SwiftUI

// MARK: - Navigation Coordinator

/// Manages app-wide navigation state and provides navigation methods
@MainActor
class NavigationCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// The navigation path (stack of routes)
    @Published var path = NavigationPath()

    /// Current sheet to present (if any)
    @Published var sheet: AppRoute?

    /// Current full screen cover to present (if any)
    @Published var fullScreenCover: AppRoute?

    // MARK: - Navigation Methods

    /// Navigate to a new route (push)
    func navigate(to route: AppRoute) {
        path.append(route)
        logNavigation(to: route)
    }

    /// Navigate to multiple routes at once (deep navigation)
    func navigate(to routes: [AppRoute]) {
        for route in routes {
            path.append(route)
        }
        if let lastRoute = routes.last {
            logNavigation(to: lastRoute)
        }
    }

    /// Pop the last route from the stack
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// Pop to root (clear entire stack)
    func popToRoot() {
        path = NavigationPath()
    }

    /// Pop to a specific depth
    func pop(to depth: Int) {
        let currentCount = path.count
        let popCount = max(0, currentCount - depth)

        for _ in 0..<popCount {
            if !path.isEmpty {
                path.removeLast()
            }
        }
    }

    /// Present a route as a sheet
    func presentSheet(_ route: AppRoute) {
        sheet = route
        logNavigation(to: route, type: "Sheet")
    }

    /// Dismiss the current sheet
    func dismissSheet() {
        sheet = nil
    }

    /// Present a route as a full screen cover
    func presentFullScreenCover(_ route: AppRoute) {
        fullScreenCover = route
        logNavigation(to: route, type: "Full Screen")
    }

    /// Dismiss the current full screen cover
    func dismissFullScreenCover() {
        fullScreenCover = nil
    }

    // MARK: - Helper Methods

    /// Get the current depth of the navigation stack
    var depth: Int {
        return path.count
    }

    /// Check if we can pop
    var canPop: Bool {
        return !path.isEmpty
    }

    // MARK: - Private Methods

    private func logNavigation(to route: AppRoute, type: String = "Push") {
        #if DEBUG
        print("🧭 Navigation [\(type)]: \(route.name)")
        #endif

        // Here you could add analytics tracking
        if route.shouldTrack {
            // Analytics.track(screen: route.name)
        }
    }
}

// MARK: - Navigation Coordinator Extensions

extension NavigationCoordinator {

    /// Navigate to product detail
    func navigateToProduct(_ product: Product) {
        navigate(to: .productDetail(product))
    }

    /// Navigate to settings
    func navigateToSettings() {
        navigate(to: .settings)
    }

    /// Navigate to language settings
    func navigateToLanguageSettings() {
        navigate(to: .languageSettings)
    }

    /// Navigate to cart
    func navigateToCart() {
        navigate(to: .cart)
    }

    /// Navigate to profile
    func navigateToProfile() {
        navigate(to: .profile)
    }
}
