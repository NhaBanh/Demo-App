import SwiftUI

// MARK: - Root Navigation View

/// The root view that manages the navigation stack and routing
struct RootNavigationView: View {
    @StateObject private var coordinator = NavigationCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .environmentObject(coordinator)
        .sheet(item: $coordinator.sheet) { route in
            sheetDestination(for: route)
        }
        .fullScreenCover(item: $coordinator.fullScreenCover) { route in
            fullScreenDestination(for: route)
        }
    }

    // MARK: - Destination Builder

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .home:
            HomeView()

        case .productDetail(let product):
            ProductDetailView(product: product)

        case .cart:
            CartView()

        case .settings:
            SettingsView()

        case .languageSettings:
            LanguageSettingsView()

        case .profile:
            ProfileView()

        case .errorDemo:
            ErrorHandlingDemoView()
        }
    }

    // MARK: - Sheet Destination Builder

    @ViewBuilder
    private func sheetDestination(for route: AppRoute) -> some View {
        NavigationStack {
            destination(for: route)
        }
    }

    // MARK: - Full Screen Destination Builder

    @ViewBuilder
    private func fullScreenDestination(for route: AppRoute) -> some View {
        NavigationStack {
            destination(for: route)
        }
    }
}

// MARK: - Preview

#Preview {
    RootNavigationView()
}
