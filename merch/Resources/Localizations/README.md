# JSON-Based Translation System

## Overview

The app now uses **JSON files** for translations, providing better scalability, maintainability, and collaboration capabilities.

## 📁 File Structure

```
merch/
└── Resources/
    └── Localizations/
        ├── en.json (English)
        ├── es.json (Spanish)
        ├── fr.json (French)
        ├── de.json (German)
        ├── ja.json (Japanese - to be added)
        ├── zh.json (Chinese - to be added)
        ├── ko.json (Korean - to be added)
        └── ar.json (Arabic - to be added)
```

## 📝 JSON File Format

Each language file follows this structure:

```json
{
  "category": {
    "key": "Translation"
  }
}
```

### Example (`en.json`):

```json
{
  "nav": {
    "home": "Home",
    "cart": "Cart"
  },
  "products": {
    "title": "Merch Shop",
    "loading": "Loading Products..."
  }
}
```

## 🔑 Translation Keys

Keys use **dot notation** for nested access:

```swift
"nav.home".localized        // "Home"
"products.title".localized  // "Merch Shop"
"error.network".localized   // "Network Error"
```

### Available Categories:

- `nav.*` - Navigation (4 keys)
- `products.*` - Product list (5 keys)
- `product.*` - Product detail (5 keys)
- `cart.*` - Shopping cart (6 keys)
- `settings.*` - Settings (5 keys)
- `common.*` - Common actions (8 keys)
- `error.*` - Error messages (3 keys)

**Total: 36 translation keys**

## ✨ Features

### 1. **Automatic JSON Loading**
- Translations load automatically from JSON files
- Falls back to hardcoded English if JSON is missing
- Logs loading status for debugging

### 2. **Nested Key Support**
```json
{
  "product": {
    "addToCart": "Add to Cart"
  }
}
```
Access with: `"product.addToCart".localized`

### 3. **Fallback System**
1. Try current language JSON
2. Fall back to English JSON
3. Fall back to hardcoded English
4. Return key if all fail

### 4. **Hot Reload**
```swift
LocalizationProvider.shared.reloadTranslations()
```

## 📋 Adding New Translations

### Step 1: Update JSON File

Edit the appropriate language file (e.g., `en.json`):

```json
{
  "myCategory": {
    "myKey": "My Translation"
  }
}
```

### Step 2: Use in Code

```swift
Text("myCategory.myKey".localized)
```

### Step 3: Add to All Languages

Repeat for all language files to maintain consistency.

## 🌐 Adding New Languages

### Step 1: Create JSON File

Create `Resources/Localizations/it.json`:

```json
{
  "nav": {
    "home": "Home",
    "cart": "Carrello"
  },
  "products": {
    "title": "Negozio di Merchandise"
  }
  // ... all other keys
}
```

### Step 2: Update AppLanguage Enum

In `LanguageManager.swift`:

```swift
enum AppLanguage: String, CaseIterable, Codable {
    // ... existing
    case italian = "it"

    var displayName: String {
        switch self {
        // ... existing
        case .italian: return "Italiano"
        }
    }

    var flag: String {
        switch self {
        // ... existing
        case .italian: return "🇮🇹"
        }
    }
}
```

### Step 3: Rebuild App

The new language will be automatically available!

## 🔧 Advanced Usage

### Format Arguments

```swift
// JSON
{
  "cart": {
    "items": "%d items in cart"
  }
}

// Swift
Text("cart.items".localized(itemCount))
```

### Check if Translation Exists

```swift
let key = "products.title"
let translation = key.localized
if translation != key {
    // Translation exists
}
```

### Manual Loading

```swift
// Reload all translations
LocalizationProvider.shared.reloadTranslations()
```

## 🎯 Benefits Over Hardcoded

| Feature | JSON Files | Hardcoded |
|---------|-----------|-----------|
| **Maintainability** | ✅ Easy to edit | ❌ Need to recompile |
| **Collaboration** | ✅ Non-devs can translate | ❌ Requires code access |
| **Scalability** | ✅ Add languages easily | ❌ Code bloat |
| **Version Control** | ✅ Clean diffs | ❌ Large code changes |
| **Remote Updates** | ✅ Possible | ❌ Requires app update |
| **Tooling** | ✅ Can use translation platforms | ❌ Manual only |
| **Testing** | ✅ Easy to mock | ⚠️ Harder |

## 🚨 Important Notes

### Bundle JSON Files

Make sure JSON files are included in the app bundle:
1. Select JSON file in Xcode
2. Check "Target Membership" → merch

### Validate JSON

Use a JSON validator before committing:
```bash
jsonlint en.json
```

### Keep Keys Consistent

All language files should have the same keys:
```bash
# Compare keys
jq 'keys' en.json
jq 'keys' es.json
```

## 🧪 Testing

### Test JSON Loading

```swift
func testJSONLoading() {
    let provider = LocalizationProvider.shared
    let title = provider.string(for: "products.title", language: .english)
    XCTAssertEqual(title, "Merch Shop")
}
```

### Test Fallback

```swift
func testFallback() {
    // If Spanish translation missing, falls back to English
    let value = "nonexistent.key".localized
    XCTAssertEqual(value, "nonexistent.key") // Returns key if not found
}
```

## 📊 Migration from Hardcoded

The system automatically falls back to hardcoded translations if JSON files are missing, ensuring zero downtime during migration.

### Migration Steps:
1. ✅ JSON files created
2. ✅ LanguageManager updated
3. ✅ Fallback system in place
4. ✅ Existing code works without changes

## 🔮 Future Enhancements

- [ ] Remote JSON loading (download translations from server)
- [ ] Translation caching
- [ ] Pluralization support
- [ ] Context-aware translations
- [ ] Translation missing detection
- [ ] Export/import tools
- [ ] Integration with translation platforms (Lokalise, Crowdin)

## 📚 Resources

- [JSON Specification](https://www.json.org/)
- [Lokalise](https://lokalise.com/) - Translation management platform
- [Crowdin](https://crowdin.com/) - Localization platform

---

**The app now uses a professional, scalable translation system! 🌍**
