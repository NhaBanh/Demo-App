# Language Management - Quick Reference

## 🚀 Quick Start

### 1. Display Localized Text

```swift
Text("products.title".localized)
```

### 2. With Format Arguments

```swift
Text("cart.items".localized(itemCount))
```

### 3. Change Language

```swift
LanguageManager.shared.setLanguage(.spanish)
```

### 4. Add Language Picker to View

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        LanguagePicker()
    }
}
```

### 5. In NavigationTitle

```swift
.navigationTitle("products.title".localized)
```

### 6. In Buttons

```swift
Button("product.addToCart".localized) {
    // Action
}
```

### 7. In Views with Auto-Refresh

```swift
struct MyView: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        Text("products.title".localized)
            .id(languageManager.currentLanguage) // Refresh on language change
    }
}
```

## 🎨 UI Components

### Full Settings Screen

```swift
NavigationLink(destination: LanguageSettingsView()) {
    Text("Change Language")
}
```

### Compact Picker

```swift
LanguagePicker()
```

### Complete Settings

```swift
SettingsView()
```

## 🔧 Programmatic Usage

### Get Current Language

```swift
let current = LanguageManager.shared.currentLanguage
print(current.displayName) // "English"
print(current.flag) // "🇺🇸"
```

### Set Language

```swift
LanguageManager.shared.setLanguage(.spanish)
```

### Check if RTL

```swift
if LanguageManager.shared.currentLanguage.isRTL {
    // Apply RTL layout
    .environment(\.layoutDirection, .rightToLeft)
}
```

## 📱 Integration Examples

### HomeView

```swift
struct HomeView: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationView {
            // ... content
            .navigationTitle("products.title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    LanguagePicker()
                }
            }
            .id(languageManager.currentLanguage)
        }
    }
}
```

### ProductDetailView

```swift
struct ProductDetailView: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        // ... content
        Text("product.quantity".localized)
        Button("product.addToCart".localized) { }
        .id(languageManager.currentLanguage)
    }
}
```

## ✅ Checklist for New Views

When creating a new view:

- [ ] Import LanguageManager if needed
- [ ] Replace all hardcoded strings with `.localized`
- [ ] Add `@ObservedObject private var languageManager = LanguageManager.shared`
- [ ] Add `.id(languageManager.currentLanguage)` to refresh on change
- [ ] Test with different languages

## 📋 Adding New Translations

### Method 1: Edit JSON Files (Recommended ✅)

#### Step 1: Edit JSON file

Open `Resources/Localizations/en.json`:

```json
{
  "myCategory": {
    "myKey": "My Translation"
  }
}
```

#### Step 2: Add to all languages

Repeat for `es.json`, `fr.json`, `de.json`, etc.

#### Step 3: Use in code

```swift
Text("myCategory.myKey".localized)
```

## 🌐 Adding New Languages

### Step 1: Add to AppLanguage Enum

```swift
enum AppLanguage: String, CaseIterable, Codable {
    // ... existing languages
    case italian = "it"

    var displayName: String {
        switch self {
        // ... existing cases
        case .italian: return "Italiano"
        }
    }

    var flag: String {
        switch self {
        // ... existing cases
        case .italian: return "🇮🇹"
        }
    }
}
```

### Step 2: Add Translations

```swift
translations[.italian] = [
    "nav.home": "Home",
    "products.title": "Negozio di Merchandise",
    // ... all translation keys
]
```

## ✅ Best Practices

### DO ✅

1. **Use translation keys consistently**
   ```swift
   Text("products.title".localized) // ✅
   ```

2. **Refresh views on language change**
   ```swift
   .id(languageManager.currentLanguage) // ✅
   ```

3. **Provide translations for all languages**
   ```swift
   // Add to all language dictionaries
   translations[.english] = [...]
   translations[.spanish] = [...]
   // ... etc
   ```
4. **Group related keys**
   ```swift
   "product.title"
   "product.description"
   "product.price"
   ```

### DON'T ❌

1. **Don't hardcode strings**
   ```swift
   Text("Add to Cart") // ❌
   Text("product.addToCart".localized) // ✅
   ```

2. **Don't forget to localize**
   ```swift
   // Check all user-facing text is localized
   ```

3. **Don't mix languages**
   ```swift
   // Keep all translations in LocalizationProvider
   ```