# Language Management System Documentation

## Architecture

```
┌─────────────────────────────────────────────────┐
│           Language Management Flow              │
├─────────────────────────────────────────────────┤
│                                                 │
│  User Selects Language                          │
│         ↓                                       │
│  LanguageManager.setLanguage()                  │
│         ↓                                       │
│  Save to UserDefaults                           │
│         ↓                                       │
│  Post Notification                              │
│         ↓                                       │
│  Views Refresh Automatically                    │
│         ↓                                       │
│  LocalizationProvider Returns Translated Text   │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Components

### 1. LanguageManager (Singleton)

Central manager for language state and persistence.

```swift
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: AppLanguage

    func setLanguage(_ language: AppLanguage)
    func localized(_ key: String) -> String
}
```

### 2. AppLanguage (Enum)

Defines all supported languages.

```swift
enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    // ... more languages

    var displayName: String
    var flag: String
    var locale: Locale
    var isRTL: Bool
}
```

**Properties:**
- `displayName` - Native language name (e.g., "Español")
- `flag` - Flag emoji (e.g., "🇪🇸")
- `locale` - Locale object for formatting
- `isRTL` - Right-to-left support flag

### 3. LocalizationProvider

Manages translation strings for all languages.

```swift
class LocalizationProvider {
    static let shared = LocalizationProvider()

    func string(for key: String, language: AppLanguage) -> String
}
```

### 4. String Extension

Convenient localization syntax.

```swift
extension String {
    var localized: String
    func localized(_ arguments: CVarArg...) -> String
}
```

---

## Testing

### Test Language Switching

```swift
func testLanguageSwitching() {
    let manager = LanguageManager.shared

    // Change to Spanish
    manager.setLanguage(.spanish)
    XCTAssertEqual(manager.currentLanguage, .spanish)

    // Verify localization
    let title = "products.title".localized
    XCTAssertEqual(title, "Tienda de Mercancía")
}
```

### Test Persistence

```swift
func testLanguagePersistence() {
    let manager = LanguageManager.shared

    // Set language
    manager.setLanguage(.french)

    // Verify saved
    let saved = UserDefaults.standard.string(forKey: "app_language")
    XCTAssertEqual(saved, "fr")
}
```

## RTL Support

For right-to-left languages (Arabic):

```swift
let isRTL = LanguageManager.shared.currentLanguage.isRTL

if isRTL {
    // Apply RTL layout
    .environment(\.layoutDirection, .rightToLeft)
}
```

## Localization Checklist

- [x] Navigation titles
- [x] Button labels
- [x] Loading messages
- [x] Error messages
- [x] Product information
- [x] Settings labels
- [x] Common actions (OK, Cancel, Save, etc.)
- [ ] Date/time formatting (future)
- [ ] Number formatting (future)
- [ ] Currency formatting (future)


## Performance Considerations

1. **Singleton Pattern** - LanguageManager is a singleton, created once
2. **Lazy Loading** - Translations loaded on first access
3. **Dictionary Lookup** - O(1) translation retrieval
4. **UserDefaults** - Minimal overhead for persistence
5. **View Refresh** - Only affected views refresh on language change

## Future Enhancements

- [ ] Load translations from JSON files
- [ ] Remote translation updates
- [ ] Pluralization support
- [ ] Context-aware translations
- [ ] Translation fallback chain
- [ ] Translation missing detection
- [ ] Export/import translations
- [ ] Crowdsourced translations
- [ ] A/B testing for translations