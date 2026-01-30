import SwiftUI

// MARK: - Profile View

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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
