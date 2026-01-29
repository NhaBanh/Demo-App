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

// MARK: - Placeholder Views

/// Placeholder for Cart View
struct CartView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Shopping Cart")
                .font(.title)
                .fontWeight(.bold)

            Text("Cart functionality coming soon!")
                .foregroundColor(.secondary)

            Button("Go Back") {
                coordinator.pop()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("cart.title".localized)
    }
}

/// Placeholder for Profile View
struct ProfileView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Profile")
                .font(.title)
                .fontWeight(.bold)

            Text("Profile functionality coming soon!")
                .foregroundColor(.secondary)

            Button("Go Back") {
                coordinator.pop()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("nav.profile".localized)
    }
}

// MARK: - Preview

#Preview {
    RootNavigationView()
}
