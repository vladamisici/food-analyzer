# 🍎 Food Analyzer iOS App


###  **Architecture**
- **MVVM + Repository Pattern** with dependency injection
- **Protocol-oriented design** for testability and modularity  
- **Result-based error handling** with comprehensive AppError types
- **Keychain security** for sensitive data storage
- **Clean separation of concerns** across layers

### **Design**
- **Custom color palette** with semantic theming
- **Typography scale** with consistent font styles
- **Spacing system** for perfect layouts
- **Component library** with reusable UI elements
- **Smooth animations** and haptic feedback

### **Features**
- **Multi-step registration** with password strength validation
- **Beautiful onboarding** with animated explanations
- **Real-time analysis progress** with visual feedback
- **Enhanced image processing** with automatic optimization
- **Rich nutrition cards** with insights and coaching tips
- **Analysis history** with local caching

### **Security & Performance**
- **Keychain Manager** for secure token storage
- **Input validation** with user-friendly error messages
- **Image optimization** for better performance
- **Offline caching** for analysis history
- **Network layer** with proper error handling
- **JWT authentication** with refresh tokens

## 📱 Project Structure

```
FoodAnalyzer/
├── FoodAnalyzerApp.swift           # App entry with state management
├── ContentView.swift               # Main navigation controller
├── DesignSystem/
│   ├── Colors.swift               # Complete color system
│   ├── Typography.swift           # Font scales & styles
│   └── Spacing.swift              # Layout system
├── Core/
│   └── Result+Extensions.swift    # Enhanced error handling
├── Utilities/
│   └── KeychainManager.swift      # Secure storage
├── Repository/
│   └── AuthRepository.swift       # Data layer abstraction
├── Services/
│   ├── APIService.swift           # Enhanced network layer
│   └── Config.swift               # Configuration
├── Models/
│   └── Models.swift               # Rich data models
├── ViewModels/
│   ├── AuthViewModel.swift        # Auth state management
│   └── FoodAnalysisViewModel.swift # Analysis logic
├── Views/
│   ├── Components/
│   │   ├── PrimaryButton.swift    # Beautiful button component
│   │   ├── CustomTextField.swift  # Enhanced input fields
│   │   └── NutritionCard.swift    # Rich result display
│   ├── LoginView.swift            # Stunning auth UI
│   ├── RegisterView.swift         # Multi-step registration
│   ├── FoodAnalysisView.swift     # Main feature UI
│   ├── PhotoPickerView.swift      # Image selection
│   └── ResultsView.swift          # Nutrition display
└── Assets.xcassets               # App assets
```

## Features

### **Core Requirements**
- **Authentication**: Register/login with JWT tokens
- **Photo Selection**: Camera and photo library integration
- **API Integration**: Food analysis with base64 image upload
- **Results Display**: Nutrition information with local editing
- **MVVM Architecture**: Clean separation of concerns

### **Features**
- **Onboarding Experience**: 3-step introduction
- **Multi-step Registration**: Progressive form with validation
- **Password Strength**: Real-time strength indicator
- **Analysis Progress**: Visual feedback during processing
- **Rich Results**: Detailed nutrition cards with insights
- **History Tracking**: Local storage of analysis results
- **Error Handling**: User-friendly error messages
- **Haptic Feedback**: Tactile interaction feedback
- **Social Login UI**: Apple/Google sign-in ready

## 🚀 Getting Started

### **Prerequisites**
- **macOS 12.0+** with **Xcode 14+**
- **Docker Desktop**

### **1. Start Backend Services**
```bash
cd ../backend_docker
docker compose up -d

# Verify services are running
curl http://localhost:5051/health  # Auth service
curl http://localhost:5052/health  # Food service
```

### **2. Open iOS Project**
```bash
open FoodAnalyzer.xcodeproj
```

- **Testable**: Protocol-based design enables easy unit testing
- **Maintainable**: Clear separation of concerns
- **Scalable**: Repository pattern supports multiple data sources
- **Secure**: Keychain storage and proper validation
- **Performant**: Image optimization and caching


### **Test User Accounts**
Pre-created accounts for testing:
- Email: `test@test.health`
- Password: `password123`
