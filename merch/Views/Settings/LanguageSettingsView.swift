import SwiftUI

// MARK: - Language Settings View

struct LanguageSettingsView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    LanguageRow(
                        language: language,
                        isSelected: languageManager.currentLanguage == language
                    ) {
                        selectLanguage(language)
                    }
                }
            } header: {
                Text("settings.language".localized)
                    .textCase(nil)
                    .font(.headline)
            } footer: {
                Text("The app will update immediately when you select a new language.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("settings.language".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func selectLanguage(_ language: AppLanguage) {
        withAnimation {
            languageManager.setLanguage(language)
        }

        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Optional: Show confirmation
        // dismiss()
    }
}

// MARK: - Language Row

struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Flag emoji
                Text(language.flag)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    // Native name
                    Text(language.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)

                    // English name (if different)
                    if language != .english {
                        Text(language.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Checkmark for selected language
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Language Picker (Compact Version)

struct LanguagePicker: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button {
                    languageManager.setLanguage(language)
                } label: {
                    HStack {
                        Text(language.flag)
                        Text(language.displayName)

                        if languageManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(languageManager.currentLanguage.flag)
                    .font(.title3)

                Text(languageManager.currentLanguage.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

struct LanguageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                LanguageSettingsView()
            }

            LanguagePicker()
                .padding()
        }
    }
}
