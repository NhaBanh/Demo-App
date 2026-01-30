# Merch App POC

This is a Proof of Concept (POC) for a merchandise selling application. It focuses on the UI and API layer implementation using SwiftUI.

## Architecture

The project follows a clean architecture pattern using **MVVM (Model-View-ViewModel)** with a **Coordinator** for navigation and a custom **Dependency Injection (DI)** system.

### Key Components

*   **UI Layer**: SwiftUI Views and ViewModels.
*   **Navigation**: `NavigationCoordinator` handles routing using `NavigationPath`, decoupling navigation logic from views.
*   **Dependency Injection**: A custom, thread-safe `DependencyContainer` that manages service lifecycles (Singleton/Transient).
*   **Services**: Protocol-oriented services (e.g., `ProductService`) with Mock and Real implementations.
*   **Models**: Simple Codable structs.

## Directory Structure

*   `merch/merchApp.swift`: App entry point.
*   `merch/DI/`: Dependency Injection container and resolver.
*   `merch/Models/`: Data models and error types.
*   `merch/Navigation/`: Navigation logic and coordination.
*   `merch/Services/`: Business logic and data fetching.
*   `merch/Views/`: UI screens organized by feature (Home, ProductDetail, Cart, Settings, Profile).
*   `merch/Resources/`: Assets and localization files.
*   `merch/Tests/`: Unit tests (needs to be added to Xcode target).

## Dependency Injection Refactoring

The Dependency Injection system has been refactored to be **thread-safe** and **synchronous** to avoid UI freezes.
-   **DependencyContainer**: Uses `NSRecursiveLock` to ensure thread safety without being an actor, allowing synchronous access.
-   **DIResolver**: A helper for constructor injection, now direct and safe to use.
-   **@Injected**: Property wrapper for easy access to dependencies.

## API & Mock Services

The app supports switching between Mock data and Real API implementations.

By default, the app uses `MockProductService`. To use the real API:
1.  Open `merch/DI/DependencyContainer.swift`.
2.  In `registerDefaults()`, toggle the logic or pass `-useRealAPI` as a launch argument.

## Running the App

1.  Open `merch.xcodeproj` in Xcode.
2.  Select the `merch` scheme.
3.  Build and Run (Cmd+R).

## Testing

A basic test structure is provided in `merch/Tests/ProductServiceTests.swift`. To run tests:
1.  Add the `merch/Tests/` folder to your Test Target in Xcode.
2.  Run Tests (Cmd+U).

## Localization

The app uses a custom `LanguageManager` for dynamic language switching. Supported languages include English, Spanish, French, German, Japanese, Chinese, Korean, and Arabic.
