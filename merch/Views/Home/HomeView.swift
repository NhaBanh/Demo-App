import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var languageManager = LanguageManager.shared
    @EnvironmentObject var coordinator: NavigationCoordinator

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("products.loading".localized)
                    .padding(.top, 50)
            } else if let error = viewModel.error {
                ErrorStateView(error: error) {
                    Task { await viewModel.retryLoadProducts() }
                }
                .padding(.top, 50)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.products) { product in
                        Button {
                            coordinator.navigateToProduct(product)
                        } label: {
                            ProductCard(product: product)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("products.title".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        coordinator.navigateToCart()
                    } label: {
                        Label("nav.cart".localized, systemImage: "cart")
                    }

                    Button {
                        coordinator.navigateToSettings()
                    } label: {
                        Label("nav.settings".localized, systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                LanguagePicker()
            }
        }
        .task {
            await viewModel.loadProducts()
        }
        .id(languageManager.currentLanguage) // Refresh view when language changes
    }
}

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: product.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 150)
            .cornerRadius(12)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(product.category)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("$\(String(format: "%.2f", product.price))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 4)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
