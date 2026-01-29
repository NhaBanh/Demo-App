import Foundation

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case chinese = "zh"
    case korean = "ko"
    case arabic = "ar"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        case .korean: return "한국어"
        case .arabic: return "العربية"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        case .korean: return "🇰🇷"
        case .arabic: return "🇸🇦"
        }
    }

    var locale: Locale {
        return Locale(identifier: rawValue)
    }

    var isRTL: Bool {
        switch self {
        case .arabic:
            return true
        default:
            return false
        }
    }

    var jsonFileName: String {
        return "\(rawValue).json"
    }
}

// MARK: - Language Manager

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            saveLanguage()
            updateLocale()
        }
    }

    private let userDefaults = UserDefaults.standard
    private let languageKey = "app_language"

    private init() {
        // Load saved language or use system default
        if let savedLanguageCode = userDefaults.string(forKey: languageKey),
           let savedLanguage = AppLanguage(rawValue: savedLanguageCode) {
            self.currentLanguage = savedLanguage
        } else {
            // Detect system language
            self.currentLanguage = Self.detectSystemLanguage()
        }

        updateLocale()
    }

    // MARK: - Public Methods

    /// Changes the app language
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language

        // Reload translations for new language
        LocalizationProvider.shared.reloadTranslations()

        // Post notification for app-wide language change
        NotificationCenter.default.post(
            name: .languageDidChange,
            object: nil,
            userInfo: ["language": language]
        )
    }

    /// Gets localized string for the current language
    func localized(_ key: String, comment: String = "") -> String {
        return LocalizationProvider.shared.string(for: key, language: currentLanguage)
    }

    /// Gets localized string with format arguments
    func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, arguments: arguments)
    }

    // MARK: - Private Methods

    private func saveLanguage() {
        userDefaults.set(currentLanguage.rawValue, forKey: languageKey)
    }

    private func updateLocale() {
        // Update app locale
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    private static func detectSystemLanguage() -> AppLanguage {
        let systemLanguageCode = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(systemLanguageCode.prefix(2))

        return AppLanguage(rawValue: languageCode) ?? .english
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - Localization Provider

class LocalizationProvider {
    static let shared = LocalizationProvider()

    private var translations: [AppLanguage: [String: Any]] = [:]
    private let fallbackLanguage: AppLanguage = .english

    private init() {
        loadAllTranslations()
    }

    /// Reload translations (useful when language changes)
    func reloadTranslations() {
        loadAllTranslations()
    }

    /// Get localized string for a key
    func string(for key: String, language: AppLanguage) -> String {
        // Try to get from current language
        if let value = getValue(for: key, language: language) {
            return value
        }

        // Fallback to English
        if language != fallbackLanguage,
           let value = getValue(for: key, language: fallbackLanguage) {
            return value
        }

        // Return key if not found
        return key
    }

    // MARK: - Private Methods

    private func loadAllTranslations() {
        for language in AppLanguage.allCases {
            loadTranslation(for: language)
        }
    }

    private func loadTranslation(for language: AppLanguage) {
        // Try to load from JSON file
        if let jsonTranslations = loadFromJSON(language: language) {
            translations[language] = jsonTranslations
            return
        }

        // Fallback to hardcoded translations if JSON not found
        translations[language] = getHardcodedTranslations(for: language)
    }

    private func loadFromJSON(language: AppLanguage) -> [String: Any]? {
        // Get bundle path
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "json", inDirectory: "Resources/Localizations") else {
            print("⚠️ Translation file not found for \(language.displayName)")
            return nil
        }

        // Read file
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("⚠️ Failed to read translation file for \(language.displayName)")
            return nil
        }

        // Parse JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ Failed to parse translation file for \(language.displayName)")
            return nil
        }

        print("✅ Loaded translations from JSON for \(language.displayName)")
        return json
    }

    private func getValue(for key: String, language: AppLanguage) -> String? {
        guard let languageTranslations = translations[language] else {
            return nil
        }

        // Split key by dots (e.g., "nav.home" -> ["nav", "home"])
        let components = key.split(separator: ".").map(String.init)

        // Navigate through nested dictionary
        var current: Any = languageTranslations
        for component in components {
            guard let dict = current as? [String: Any],
                  let next = dict[component] else {
                return nil
            }
            current = next
        }

        return current as? String
    }

    /// Hardcoded fallback translations (used if JSON files are missing)
    private func getHardcodedTranslations(for language: AppLanguage) -> [String: Any] {
        print("⚠️ Using hardcoded fallback for \(language.displayName)")

        switch language {
        case .english:
            return [
                "nav": ["home": "Home", "cart": "Cart", "profile": "Profile", "settings": "Settings"],
                "products": ["title": "Merch Shop", "loading": "Loading Products...", "empty": "No products available", "error": "Failed to load products", "retry": "Retry"],
                "product": ["quantity": "Quantity", "addToCart": "Add to Cart", "price": "Price", "description": "Description", "category": "Category"],
                "cart": ["title": "Shopping Cart", "empty": "Your cart is empty", "total": "Total", "checkout": "Checkout", "remove": "Remove", "clear": "Clear Cart"],
                "settings": ["title": "Settings", "language": "Language", "theme": "Theme", "notifications": "Notifications", "about": "About"],
                "common": ["ok": "OK", "cancel": "Cancel", "save": "Save", "delete": "Delete", "edit": "Edit", "done": "Done", "close": "Close", "search": "Search"],
                "error": ["network": "Network Error", "unknown": "Unknown Error", "tryAgain": "Please try again"]
            ]
        default:
            // For other languages, return empty and fall back to English
            return [:]
        }
    }
}

// MARK: - String Extension for Easy Localization

extension String {
    /// Returns the localized version of this string
    var localized: String {
        return LanguageManager.shared.localized(self)
    }

    /// Returns the localized version with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        let format = LanguageManager.shared.localized(self)
        return String(format: format, arguments: arguments)
    }
}
