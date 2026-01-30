import SwiftUI

// MARK: - Cart View

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

// MARK: - Preview

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
    }
}
