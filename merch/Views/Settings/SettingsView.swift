import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        List {
            // Language Section
            Section {
                Button {
                    coordinator.navigateToLanguageSettings()
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.accentColor)
                            .frame(width: 28)

                        Text("settings.language".localized)
                            .foregroundColor(.primary)

                        Spacer()

                        Text(languageManager.currentLanguage.flag)
                        Text(languageManager.currentLanguage.displayName)
                            .foregroundColor(.secondary)
                            .font(.subheadline)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Preferences")
            }

            // Other Settings Sections
            Section {
                SettingsRow(
                    icon: "bell.fill",
                    title: "settings.notifications".localized,
                    color: .orange
                )

                SettingsRow(
                    icon: "paintbrush.fill",
                    title: "settings.theme".localized,
                    color: .purple
                )
            } header: {
                Text("Appearance")
            }

            Section {
                SettingsRow(
                    icon: "info.circle.fill",
                    title: "settings.about".localized,
                    color: .blue
                )
            } header: {
                Text("Information")
            }
        }
        .navigationTitle("settings.title".localized)
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)

            Text(title)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
