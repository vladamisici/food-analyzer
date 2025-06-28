# 🍎 Food Analyzer iOS App

This is a SwiftUI-based iOS application for food analysis. It's built with a focus on a clean, scalable architecture and a rich, modern user experience. The project demonstrates a robust implementation of MVVM, a repository pattern for data management, and a comprehensive design system.

---

### Core Architecture

The application is architected around a **protocol-oriented MVVM** pattern, ensuring a clear separation between the view, its state, and the business logic.

-   **MVVM:** Each feature is broken down into a `View` (UI), a `ViewModel` (state and logic), and `Models` (data structures). This keeps the code organized, testable, and easy to reason about.
-   **Repository Pattern:** Data access is abstracted through a repository layer (`AuthRepository`, `HistoryRepository`, `GoalsRepository`). This decouples the ViewModels from the specific data sources (Core Data, Keychain, API), making it easy to swap implementations or add caching layers.
-   **Dependency Injection (DI):** A simple `DependencyContainer` is used to manage and inject dependencies like repositories and services. This promotes loose coupling and enhances testability.
-   **Core Data & Keychain:** Local data persistence is handled by Core Data for structured data like analysis history and goals. Sensitive information, such as auth tokens, is securely stored in the Keychain using a `KeychainManager` wrapper.
-   **Robust Error Handling:** The app uses a `Result`-based error handling system with a set of custom `AppError` types. This ensures that errors from the network, storage, or validation layers are handled gracefully and provide clear, user-friendly feedback.
-   **Networking:** All API interactions are managed by a protocol-based `APIService`, making it straightforward to mock for testing. The service includes configurations for different backend environments.

### Key Features

-   **Authentication:**
    -   Secure, multi-step registration flow with real-time password strength validation.
    -   JWT-based authentication with secure token storage in the Keychain.
    -   Elegant onboarding and login screens with a polished UI.

-   **Food Analysis:**
    -   Image selection from the camera or photo library using `PhotosPicker`.
    -   Client-side image optimization before upload to reduce network load.
    -   Real-time visual feedback on the analysis progress (`Uploading`, `Processing`, `Complete`).
    -   Results are displayed in rich, animated `NutritionCard` components.

-   **History & Goals:**
    -   Persistent storage of analysis history and nutrition goals using Core Data.
    -   Comprehensive history view with filtering (date range, health score) and sorting capabilities.
    -   A dedicated goals screen with progress tracking, visualised through animated `ProgressRing` components.
    -   Personalized goal recommendations based on user profile data (age, weight, activity level, etc.).

### Tech Stack

-   **Framework:** SwiftUI
-   **State Management:** Combine for reactive data binding.
-   **Architecture:** MVVM, Repository Pattern, Protocol-Oriented Programming
-   **Database:** Core Data
-   **Networking:** URLSession
-   **Security:** Keychain

### Getting Started

#### Prerequisites

-   **macOS 12.0+** with **Xcode 14+**
-   **Docker Desktop**

#### 1. Start Backend Services

```bash
# Navigate to the backend directory
cd ../backend_docker

# Start the services in detached mode
docker compose up -d

# Verify that the services are running
curl http://localhost:5051/health  # Auth service should return OK
curl http://localhost:5052/health  # Food service should return OK
```

2. Open iOS Project

```Bash
open FoodAnalyzer.xcodeproj
Build and run the project in Xcode.
```

Test User Accounts
A pre-created account is available for testing:

Email: test@test.health

Password: password123

Project Structure
```Bash
FoodAnalyzer/
├── FoodAnalyzerApp.swift           # App entry point, manages global state
├── ContentView.swift               # Root view, handles navigation (onboarding, auth, main)
│
├── DesignSystem/                   # Reusable UI elements and styles
│   ├── Colors.swift                # App-wide color theme
│   ├── Typography.swift            # Font styles and scales
│   └── Spacing.swift               # Spacing and layout system
│
├── Core/
│   └── Result+Extensions.swift     # Custom Result type and AppError enums
│
├── Utilities/
│   ├── KeychainManager.swift       # Secure wrapper for Keychain access
│   └── HapticManager.swift         # Centralized haptic feedback control
│
├── Services/
│   ├── APIService.swift            # Handles all network requests
│   └── Config.swift                # Backend service configuration
│
├── Models/
│   └── Models.swift                # Data models (User, AuthResponse, etc.)
│
├── ViewModels/
│   ├── AuthViewModel.swift         # Manages authentication state and logic
│   ├── FoodAnalysisViewModel.swift # Handles image selection and analysis flow
│   ├── HistoryViewModel.swift      # Manages history and analytics data
│   └── GoalsViewModel.swift        # Manages nutrition goals and progress
│
├── Views/
│   ├── Components/                 # Reusable SwiftUI views
│   │   ├── PrimaryButton.swift
│   │   ├── CustomTextField.swift
│   │   ├── NutritionCard.swift
│   │   ├── ChartView.swift
│   │   ├── ProgressRing.swift
│   │   └── AchievementCard.swift
│   │
│   ├── LoginView.swift             # Handles user login
│   ├── RegisterView.swift          # Multi-step user registration
│   ├── EnhancedFoodAnalysisView.swift  # Main screen for food analysis
│   ├── EnhancedHistoryView.swift       # Displays analysis history and analytics
│   └── EnhancedGoalsView.swift         # Displays user goals and progress
│
├── CoreData/
│   ├── CoreDataManager.swift       # Singleton to manage the Core Data stack
│   ├── FoodAnalysisEntity+...      # Core Data model for food analysis
│   └── NutritionGoalEntity+...     # Core Data model for nutrition goals
│
└── Repository/
    ├── AuthRepository.swift        # Handles authentication-related data operations
    ├── CoreDataHistoryRepository.swift # Implements history repository with Core Data
    └── CoreDataGoalsRepository.swift   # Implements goals repository with Core Data```
