# NavigationStack Implementation Guide

## ✅ What Was Implemented

A modern **NavigationStack-based** navigation system using the Coordinator pattern for clean, testable, and maintainable navigation.

---

## 📁 File Structure

```
merch/
├── Navigation/
│   ├── AppRoute.swift ✅
│   ├── NavigationCoordinator.swift ✅
│   └── RootNavigationView.swift ✅
├── merchApp.swift ✅ (Updated)
└── Views/
    ├── Home/
    │   └── HomeView.swift ✅ (Updated)
    └── Settings/
        └── LanguageSettingsView.swift ✅ (Updated)
```

---

## 🎯 Key Components

### 1. **AppRoute** - Type-Safe Routes

Defines all possible navigation destinations:

```swift
enum AppRoute: Hashable {
    case home
    case productDetail(Product)
    case cart
    case settings
    case languageSettings
    case profile
}
```

**Benefits:**
- ✅ Type-safe navigation
- ✅ Compile-time checking
- ✅ Easy to extend
- ✅ Supports parameters (e.g., `Product`)

---

### 2. **NavigationCoordinator** - Navigation Manager

Manages the navigation state and provides navigation methods:

```swift
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to route: AppRoute)
    func pop()
    func popToRoot()
    func presentSheet(_ route: AppRoute)
    func presentFullScreenCover(_ route: AppRoute)
}
```

**Features:**
- ✅ Push navigation
- ✅ Pop navigation
- ✅ Deep navigation (multiple screens at once)
- ✅ Sheet presentation
- ✅ Full screen covers
- ✅ Navigation logging

---

### 3. **RootNavigationView** - Navigation Container

The root view that sets up the NavigationStack:

```swift
struct RootNavigationView: View {
    @StateObject private var coordinator = NavigationCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .environmentObject(coordinator)
    }
}
```

---

## 🚀 How to Use

### Basic Navigation

```swift
struct MyView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        Button("Go to Settings") {
            coordinator.navigate(to: .settings)
        }
    }
}
```

### Navigate with Parameters

```swift
Button("View Product") {
    coordinator.navigate(to: .productDetail(product))
}

// Or use convenience method
coordinator.navigateToProduct(product)
```

### Pop Navigation

```swift
Button("Go Back") {
    coordinator.pop()
}

Button("Go to Home") {
    coordinator.popToRoot()
}
```

### Present Sheet

```swift
Button("Show Settings") {
    coordinator.presentSheet(.settings)
}
```

### Present Full Screen

```swift
Button("Show Profile") {
    coordinator.presentFullScreenCover(.profile)
}
```

---

## 📝 Adding New Routes

### Step 1: Add to AppRoute

```swift
enum AppRoute: Hashable {
    // ... existing routes
    case checkout
    case orderHistory
}
```

### Step 2: Add Destination in RootNavigationView

```swift
@ViewBuilder
private func destination(for route: AppRoute) -> some View {
    switch route {
    // ... existing cases
    case .checkout:
        CheckoutView()
    case .orderHistory:
        OrderHistoryView()
    }
}
```

### Step 3: Add Convenience Method (Optional)

```swift
extension NavigationCoordinator {
    func navigateToCheckout() {
        navigate(to: .checkout)
    }
}
```

### Step 4: Use in Views

```swift
Button("Checkout") {
    coordinator.navigateToCheckout()
}
```

---

## ✨ Features & Benefits

### Type Safety ✅
```swift
// Compile-time error if route doesn't exist
coordinator.navigate(to: .invalidRoute) // ❌ Won't compile
```

### Programmatic Navigation ✅
```swift
// Navigate from anywhere (ViewModels, etc.)
coordinator.navigate(to: .settings)
```

### Deep Navigation ✅
```swift
// Navigate multiple levels at once
coordinator.navigate(to: [.settings, .languageSettings])
```

### Navigation Logging ✅
```swift
// Automatic logging in debug mode
🧭 Navigation [Push]: Product Detail
🧭 Navigation [Sheet]: Settings
```

### Easy Testing ✅
```swift
func testNavigation() {
    let coordinator = NavigationCoordinator()
    coordinator.navigate(to: .settings)
    XCTAssertEqual(coordinator.depth, 1)
}
```

---

## 🎨 Updated Views

### HomeView
- ✅ Removed `NavigationView`
- ✅ Removed `NavigationLink`
- ✅ Added `@EnvironmentObject var coordinator`
- ✅ Uses `Button` + `coordinator.navigate()`
- ✅ Added menu with Cart and Settings

### SettingsView
- ✅ Removed `NavigationView`
- ✅ Removed `NavigationLink`
- ✅ Added `@EnvironmentObject var coordinator`
- ✅ Uses `Button` + `coordinator.navigate()`

---

## 🔧 Advanced Usage

### Check Navigation State

```swift
// Check if we can pop
if coordinator.canPop {
    coordinator.pop()
}

// Get current depth
let depth = coordinator.depth
```

### Pop to Specific Depth

```swift
// Pop to depth 1 (keep only root + 1 screen)
coordinator.pop(to: 1)
```

### Custom Back Button

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("Back") {
            coordinator.pop()
        }
    }
}
```

---

## 📊 Comparison: Before vs After

### Before (NavigationLink)

```swift
NavigationView {
    List {
        NavigationLink(destination: SettingsView()) {
            Text("Settings")
        }
    }
}
```

**Issues:**
- ❌ Hard to navigate programmatically
- ❌ Difficult to test
- ❌ No centralized navigation logic
- ❌ Can't navigate from ViewModels

### After (NavigationStack + Coordinator)

```swift
Button("Settings") {
    coordinator.navigateToSettings()
}
```

**Benefits:**
- ✅ Programmatic navigation
- ✅ Easy to test
- ✅ Centralized navigation logic
- ✅ Can navigate from anywhere
- ✅ Type-safe routes
- ✅ Deep linking ready

---

## 🧪 Testing

### Test Navigation

```swift
@MainActor
func testNavigateToSettings() {
    let coordinator = NavigationCoordinator()

    coordinator.navigateToSettings()

    XCTAssertEqual(coordinator.depth, 1)
}
```

### Test Pop

```swift
@MainActor
func testPop() {
    let coordinator = NavigationCoordinator()

    coordinator.navigate(to: .settings)
    coordinator.navigate(to: .languageSettings)

    XCTAssertEqual(coordinator.depth, 2)

    coordinator.pop()

    XCTAssertEqual(coordinator.depth, 1)
}
```

---

## 🎯 Best Practices

### ✅ DO

1. **Use coordinator for all navigation**
   ```swift
   coordinator.navigate(to: .settings)
   ```

2. **Add convenience methods for common routes**
   ```swift
   coordinator.navigateToSettings()
   ```

3. **Use type-safe routes**
   ```swift
   case productDetail(Product) // ✅ Type-safe
   ```

4. **Inject coordinator via environment**
   ```swift
   @EnvironmentObject var coordinator: NavigationCoordinator
   ```

### ❌ DON'T

1. **Don't use NavigationLink for push navigation**
   ```swift
   NavigationLink(destination: SettingsView()) { } // ❌
   ```

2. **Don't create multiple coordinators**
   ```swift
   @StateObject var coordinator = NavigationCoordinator() // ❌
   // Use @EnvironmentObject instead
   ```

3. **Don't hardcode navigation**
   ```swift
   // ❌ Bad
   NavigationLink(destination: ProductDetailView(product: product))

   // ✅ Good
   coordinator.navigateToProduct(product)
   ```

---

## 🔮 Future Enhancements

- [ ] Deep linking support
- [ ] URL-based navigation
- [ ] Navigation analytics
- [ ] Navigation history
- [ ] Custom transitions
- [ ] Tab bar integration
- [ ] Navigation state persistence

---

## 📚 Resources

- [Apple - NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)
- [Apple - NavigationPath](https://developer.apple.com/documentation/swiftui/navigationpath)
- [WWDC 2022 - The SwiftUI cookbook for navigation](https://developer.apple.com/videos/play/wwdc2022/10054/)

---

## 🎉 Summary

**Your app now has a modern, production-ready navigation system!**

✅ **NavigationStack** - Modern SwiftUI navigation
✅ **Type-safe routes** - Compile-time safety
✅ **Coordinator pattern** - Centralized navigation
✅ **Programmatic navigation** - Navigate from anywhere
✅ **Easy testing** - Testable navigation logic
✅ **Clean code** - No NavigationLink clutter
✅ **Scalable** - Easy to add new routes

**All existing views updated and working!** 🚀
