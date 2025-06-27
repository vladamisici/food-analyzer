import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            if appState.showOnboarding {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                EnhancedLoginView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: appState.showOnboarding)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: authViewModel.isAuthenticated)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Analysis Tab
            NavigationView {
                EnhancedFoodAnalysisView()
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "camera.fill" : "camera")
                Text("Analyze")
            }
            .tag(0)
            
            // History Tab
            EnhancedHistoryView()
            .tabItem {
                Image(systemName: selectedTab == 1 ? "clock.fill" : "clock")
                Text("History")
            }
            .tag(1)
            
            // Goals Tab
            EnhancedGoalsView()
            .tabItem {
                Image(systemName: selectedTab == 2 ? "target" : "target")
                Text("Goals")
            }
            .tag(2)
            
            // Profile Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                Text("Profile")
            }
            .tag(3)
        }
        .accentColor(Color.theme.primary)
        .background(Color.theme.background)
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Analyze Your Food",
            subtitle: "Take a photo of any meal to get instant nutrition insights",
            imageName: "camera.macro",
            gradientColors: [Color.theme.primary]
        ),
        OnboardingPage(
            title: "Track Your Goals",
            subtitle: "Set personalized nutrition goals and track your progress",
            imageName: "target",
            gradientColors: [Color.theme.secondary]
        ),
        OnboardingPage(
            title: "Get Insights",
            subtitle: "Receive personalized coaching tips and meal recommendations",
            imageName: "lightbulb.fill",
            gradientColors: [Color.theme.accent]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Bottom Section
            VStack(spacing: .spacing.xl) {
                // Page Indicator
                HStack(spacing: .spacing.sm) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.theme.primary : Color.theme.textTertiary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                
                // Action Buttons
                if currentPage == pages.count - 1 {
                    PrimaryButton("Get Started", style: .primary) {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            appState.showOnboarding = false
                        }
                    }
                    .containerPadding()
                } else {
                    HStack {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                                appState.showOnboarding = false
                            }
                        }
                        .titleMedium(Color.theme.textSecondary)
                        
                        Spacer()
                        
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage = min(currentPage + 1, pages.count - 1)
                            }
                        }
                        .titleMedium(Color.theme.primary)
                    }
                    .containerPadding()
                }
            }
            .background(Color.theme.surface)
        }
        .background(Color.theme.background)
    }
    
    private func onboardingPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: .spacing.xxxl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    //.fill(page.color.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: page.imageName)
                    .font(.system(size: 60))
                    //.foregroundColor(page.color)
            }
            
            // Text Content
            VStack(spacing: .spacing.lg) {
                Text(page.title)
                    .headlineLarge()
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .bodyLarge(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .containerPadding()
            }
            
            Spacer()
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: .spacing.xl) {
            // Profile Header
            VStack(spacing: .spacing.md) {
                // Avatar
                Circle()
                    .fill(Color.theme.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(authViewModel.currentUser?.initials ?? "")
                            .headlineMedium(Color.theme.primary)
                    )
                
                VStack(spacing: .spacing.xs) {
                    Text(authViewModel.currentUser?.fullName ?? "")
                        .titleLarge()
                    
                    Text(authViewModel.currentUser?.email ?? "")
                        .bodyMedium()
                        .foregroundColor(Color.theme.textSecondary)
                }
            }
            .containerPadding()
            
            Spacer()
            
            // Logout Button
            PrimaryButton("Sign Out", style: .destructive) {
                Task {
                    await authViewModel.logout()
                }
            }
            .containerPadding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
        .navigationBarHidden(true)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
