import SwiftUI
import Combine

@main
struct FoodAnalyzerApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(appState.authViewModel)
                .environmentObject(appState.foodAnalysisViewModel)
                .preferredColorScheme(appState.colorScheme)
                .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Configure app appearance
        setupAppearance()
        
        // Start background tasks
        Task {
            await appState.initialize()
        }
    }
    
    private func setupAppearance() {
        // Navigation Bar Appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.theme.surface)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.theme.textPrimary),
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Tab Bar Appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.theme.surface)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - App State Manager
@MainActor
final class AppState: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil
    @Published var isFirstLaunch = true
    @Published var showOnboarding = false
    
    // View Models
    let authViewModel: AuthViewModel
    let foodAnalysisViewModel: FoodAnalysisViewModel
    let historyViewModel: HistoryViewModel
    let goalsViewModel: GoalsViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let container = DependencyContainer.shared
        
        self.authViewModel = AuthViewModel(authRepository: container.authRepository)
        self.historyViewModel = HistoryViewModel(historyRepository: container.historyRepository)
        self.goalsViewModel = GoalsViewModel(goalsRepository: container.goalsRepository)
        self.foodAnalysisViewModel = FoodAnalysisViewModel()
        
        // Setup user sync
        authViewModel.$currentUser
            .sink { [weak self] user in
                container.setupUserForRepositories(user)
            }
            .store(in: &cancellables)
    }
    
    // Settings
    @Published var hapticFeedbackEnabled = true
    @Published var notificationsEnabled = true
    
    func initialize() async {
        // Check if first launch
        checkFirstLaunch()
        
        // Load user preferences
        loadUserPreferences()
        
        // Refresh auth session if needed
        await authViewModel.refreshSession()
    }
    
    private func checkFirstLaunch() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        showOnboarding = isFirstLaunch
        
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    private func loadUserPreferences() {
        // Load color scheme preference
        if let scheme = UserDefaults.standard.object(forKey: "colorScheme") as? String {
            switch scheme {
            case "dark":
                colorScheme = .dark
            case "light":
                colorScheme = .light
            default:
                colorScheme = nil
            }
        }
        
        // Load other preferences
        hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    func updateColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        
        let schemeString: String
        switch scheme {
        case .dark:
            schemeString = "dark"
        case .light:
            schemeString = "light"
        case .none:
            schemeString = "auto"
        }
        
        UserDefaults.standard.set(schemeString, forKey: "colorScheme")
    }
}