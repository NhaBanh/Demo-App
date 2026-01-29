import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var quantity = 1
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncImage(url: URL(string: product.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.1))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .cornerRadius(20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(product.category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)

                        Spacer()

                        Text("$\(String(format: "%.2f", product.price))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }

                    Text(product.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(product.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                HStack {
                    Text("product.quantity".localized)
                        .font(.headline)

                    Spacer()

                    Stepper(value: $quantity, in: 1...99) {
                        Text("\(quantity)")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .fixedSize()
                }
                .padding(.horizontal)

                Button(action: {
                    // Add to cart logic would go here
                    print("Added \(quantity) of \(product.name) to cart")
                }) {
                    Text("product.addToCart".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .id(languageManager.currentLanguage) // Refresh when language changes
    }
}
