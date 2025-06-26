import SwiftUI

struct EnhancedGoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var showWelcomeSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasGoals {
                    welcomeView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.hasGoals {
                        Button(action: { viewModel.showAchievements = true }) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(Color.theme.warning)
                        }
                        
                        Button(action: viewModel.startEditingGoals) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Color.theme.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isEditingGoals) {
                goalEditingSheet
            }
            .sheet(isPresented: $viewModel.showAchievements) {
                achievementsSheet
            }
            .sheet(isPresented: $viewModel.showProfileSetup) {
                profileSetupSheet
            }
            .sheet(isPresented: $viewModel.showGoalRecommendations) {
                recommendationsSheet
            }
            .overlay(
                successToast,
                alignment: .top
            )
            .overlay(
                errorToast,
                alignment: .top
            )
        }
        .onAppear {
            if !viewModel.hasGoals {
                showWelcomeSheet = true
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: .spacing.xl) {
                // Today's Progress Header
                todayProgressHeader
                
                // Progress Rings
                progressRingsSection
                
                // Progress Detail Cards
                progressDetailSection
                
                // Weekly/Monthly Overview
                periodOverviewSection
                
                // Motivational Section
                motivationalSection
                
                // Quick Actions
                quickActionsSection
            }
            .padding(.vertical, .spacing.lg)
        }
        .refreshable {
            viewModel.loadProgress()
        }
    }
    
    private var todayProgressHeader: some View {
        VStack(spacing: .spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing.xs) {
                    Text("Today's Progress")
                        .headlineMedium()
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text(viewModel.motivationalMessage)
                        .bodyMedium()
                        .foregroundColor(Color.theme.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Overall completion percentage
                ZStack {
                    ProgressRing(
                        progress: viewModel.todayGoalCompletion,
                        lineWidth: 6,
                        size: 60,
                        gradient: LinearGradient(
                            colors: viewModel.isOnTrack ? 
                                [Color.theme.success, Color.theme.success.opacity(0.6)] :
                                [Color.theme.primary, Color.theme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    Text("\(Int(viewModel.todayGoalCompletion * 100))%")
                        .labelMedium()
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.textPrimary)
                }
            }
            
            // Streak indicator
            if viewModel.streakDays > 0 {
                HStack(spacing: .spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color.theme.warning)
                    
                    Text("\(viewModel.streakDays) day streak!")
                        .labelMedium()
                        .foregroundColor(Color.theme.warning)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if viewModel.isOnTrack {
                        HStack(spacing: .spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.theme.success)
                            
                            Text("On Track")
                                .labelMedium()
                                .foregroundColor(Color.theme.success)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal, .spacing.md)
                .padding(.vertical, .spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                        .fill(Color.theme.warning.opacity(0.1))
                )
            }
        }
        .containerPadding()
    }
    
    private var progressRingsSection: some View {
        HStack(spacing: .spacing.lg) {
            if let goals = viewModel.currentGoals {
                ProgressRingWithLabel(
                    title: "Calories",
                    progress: viewModel.dailyProgress.calorieProgress,
                    current: "\(viewModel.dailyProgress.totalCalories)",
                    target: "\(goals.dailyCalorieGoal)",
                    color: Color.theme.primary,
                    size: 90
                )
                
                ProgressRingWithLabel(
                    title: "Protein",
                    progress: viewModel.dailyProgress.proteinProgress,
                    current: "\(Int(viewModel.dailyProgress.totalProtein))g",
                    target: "\(Int(goals.proteinGoal))g",
                    color: Color.theme.secondary,
                    size: 90
                )
                
                ProgressRingWithLabel(
                    title: "Carbs",
                    progress: viewModel.dailyProgress.carbsProgress,
                    current: "\(Int(viewModel.dailyProgress.totalCarbs))g",
                    target: "\(Int(goals.carbsGoal))g",
                    color: Color.theme.warning,
                    size: 90
                )
                
                ProgressRingWithLabel(
                    title: "Fat",
                    progress: viewModel.dailyProgress.fatProgress,
                    current: "\(Int(viewModel.dailyProgress.totalFat))g",
                    target: "\(Int(goals.fatGoal))g",
                    color: Color.theme.accent,
                    size: 90
                )
            }
        }
        .containerPadding()
    }
    
    private var progressDetailSection: some View {
        VStack(spacing: .spacing.md) {
            HStack {
                Text("Daily Breakdown")
                    .titleMedium()
                    .foregroundColor(Color.theme.textPrimary)
                
                Spacer()
                
                Picker("Period", selection: $viewModel.selectedProgressPeriod) {
                    ForEach(ProgressPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .containerPadding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.md) {
                if let goals = viewModel.currentGoals {
                    DetailProgressCard(
                        title: "Calories",
                        current: viewModel.dailyProgress.totalCalories,
                        target: goals.dailyCalorieGoal,
                        unit: "kcal",
                        icon: "flame.fill",
                        color: Color.theme.primary,
                        progress: viewModel.dailyProgress.calorieProgress
                    )
                    
                    DetailProgressCard(
                        title: "Protein",
                        current: Int(viewModel.dailyProgress.totalProtein),
                        target: Int(goals.proteinGoal),
                        unit: "g",
                        icon: "bolt.fill",
                        color: Color.theme.secondary,
                        progress: viewModel.dailyProgress.proteinProgress
                    )
                    
                    DetailProgressCard(
                        title: "Carbohydrates",
                        current: Int(viewModel.dailyProgress.totalCarbs),
                        target: Int(goals.carbsGoal),
                        unit: "g",
                        icon: "leaf.fill",
                        color: Color.theme.warning,
                        progress: viewModel.dailyProgress.carbsProgress
                    )
                    
                    DetailProgressCard(
                        title: "Fat",
                        current: Int(viewModel.dailyProgress.totalFat),
                        target: Int(goals.fatGoal),
                        unit: "g",
                        icon: "drop.fill",
                        color: Color.theme.accent,
                        progress: viewModel.dailyProgress.fatProgress
                    )
                }
            }
            .containerPadding()
        }
    }
    
    private var periodOverviewSection: some View {
        VStack(spacing: .spacing.lg) {
            // Weekly overview
            if let weeklyProgress = viewModel.weeklyProgress {
                WeeklyOverviewCard(weeklyProgress: weeklyProgress)
                    .containerPadding()
            }
            
            // Monthly overview
            if let monthlyProgress = viewModel.monthlyProgress {
                MonthlyOverviewCard(monthlyProgress: monthlyProgress)
                    .containerPadding()
            }
        }
    }
    
    private var motivationalSection: some View {
        VStack(spacing: .spacing.md) {
            // Achievement highlights
            if !viewModel.unlockedAchievements.isEmpty {
                VStack(alignment: .leading, spacing: .spacing.md) {
                    HStack {
                        Text("Recent Achievements")
                            .titleMedium()
                            .foregroundColor(Color.theme.textPrimary)
                        
                        Spacer()
                        
                        Button("View All") {
                            viewModel.showAchievements = true
                        }
                        .labelMedium(Color.theme.primary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .spacing.md) {
                            ForEach(viewModel.unlockedAchievements.prefix(3)) { achievement in
                                AchievementCard(achievement: achievement, isCompact: true)
                                    .frame(width: 280)
                            }
                        }
                        .padding(.horizontal, .spacing.containerPadding)
                    }
                }
            }
            
            // Motivational tip
            MotivationalTipCard()
                .containerPadding()
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: .spacing.md) {
            HStack {
                Text("Quick Actions")
                    .titleMedium()
                    .foregroundColor(Color.theme.textPrimary)
                
                Spacer()
            }
            .containerPadding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.md) {
                QuickActionCard(
                    title: "Log Food",
                    icon: "camera.fill",
                    color: Color.theme.primary
                ) {
                    // Navigate to food analysis
                }
                
                QuickActionCard(
                    title: "Share Progress",
                    icon: "square.and.arrow.up",
                    color: Color.theme.secondary
                ) {
                    viewModel.shareProgress()
                }
                
                QuickActionCard(
                    title: "Recommendations",
                    icon: "lightbulb.fill",
                    color: Color.theme.warning
                ) {
                    viewModel.showProfileSetup = true
                }
                
                QuickActionCard(
                    title: "View History",
                    icon: "clock.fill",
                    color: Color.theme.accent
                ) {
                    // Navigate to history
                }
            }
            .containerPadding()
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: .spacing.xxl) {
            // Illustration
            VStack(spacing: .spacing.lg) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.theme.primary.opacity(0.2), Color.theme.secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(Color.theme.primary)
                }
                
                VStack(spacing: .spacing.md) {
                    Text("Set Your Goals")
                        .headlineLarge()
                        .foregroundColor(Color.theme.textPrimary)
                        .fontWeight(.bold)
                    
                    Text("Define your nutrition targets and start tracking your progress towards a healthier you!")
                        .bodyLarge()
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .containerPadding()
                }
            }
            
            // Benefits
            VStack(spacing: .spacing.lg) {
                BenefitRow(icon: "chart.line.uptrend.xyaxis", title: "Track Progress", description: "Monitor your daily nutrition intake")
                BenefitRow(icon: "lightbulb.fill", title: "Get Insights", description: "Receive personalized recommendations")
                BenefitRow(icon: "trophy.fill", title: "Earn Achievements", description: "Unlock rewards as you hit your goals")
            }
            .containerPadding()
            
            // Action buttons
            VStack(spacing: .spacing.md) {
                PrimaryButton("Get Recommendations", style: .primary) {
                    viewModel.showProfileSetup = true
                }
                
                PrimaryButton("Set Goals Manually", style: .secondary) {
                    viewModel.startEditingGoals()
                }
            }
            .containerPadding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: .spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.theme.primary)
            
            Text("Loading your goals...")
                .bodyMedium()
                .foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Sheets
    private var goalEditingSheet: some View {
        NavigationView {
            GoalEditingView(viewModel: viewModel)
        }
    }
    
    private var achievementsSheet: some View {
        NavigationView {
            AchievementsView(viewModel: viewModel)
        }
    }
    
    private var profileSetupSheet: some View {
        NavigationView {
            ProfileSetupView(viewModel: viewModel)
        }
    }
    
    private var recommendationsSheet: some View {
        NavigationView {
            RecommendationsView(viewModel: viewModel)
        }
    }
    
    // MARK: - Toasts
    private var successToast: some View {
        Group {
            if viewModel.showSuccessMessage, let message = viewModel.successMessage {
                ToastView(message: message, type: .success)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.showSuccessMessage)
    }
    
    private var errorToast: some View {
        Group {
            if viewModel.showError, let message = viewModel.errorMessage {
                ToastView(message: message, type: .error)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.showError)
    }
}

// MARK: - Supporting Views
struct DetailProgressCard: View {
    let title: String
    let current: Int
    let target: Int
    let unit: String
    let icon: String
    let color: Color
    let progress: Double
    
    var remaining: Int {
        max(0, target - current)
    }
    
    var isOverTarget: Bool {
        current > target
    }
    
    var body: some View {
        VStack(spacing: .spacing.md) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .labelMedium()
                    .foregroundColor(Color.theme.textSecondary)
                
                Spacer()
                
                if isOverTarget {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.theme.warning)
                        .font(.caption)
                }
            }
            
            // Progress
            VStack(spacing: .spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing.xs) {
                    Text("\(current)")
                        .titleLarge()
                        .foregroundColor(Color.theme.textPrimary)
                        .fontWeight(.bold)
                    
                    Text("/ \(target) \(unit)")
                        .bodyMedium()
                        .foregroundColor(Color.theme.textSecondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.theme.textTertiary.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: isOverTarget ? 
                                        [Color.theme.warning, Color.theme.error] :
                                        [color, color.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * min(progress, 1.0),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
                
                // Remaining/status text
                HStack {
                    if isOverTarget {
                        Text("\(current - target) \(unit) over")
                            .font(.caption)
                            .foregroundColor(Color.theme.warning)
                    } else if remaining > 0 {
                        Text("\(remaining) \(unit) remaining")
                            .font(.caption)
                            .foregroundColor(Color.theme.textTertiary)
                    } else {
                        Text("Goal achieved!")
                            .font(.caption)
                            .foregroundColor(Color.theme.success)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                }
            }
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                        .strokeBorder(
                            color.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct WeeklyOverviewCard: View {
    let weeklyProgress: WeeklyProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing.xs) {
                    Text("This Week")
                        .titleMedium()
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text("Weekly nutrition overview")
                        .labelMedium()
                        .foregroundColor(Color.theme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: .spacing.xs) {
                    Text("\(Int(weeklyProgress.goalCompletionRate * 100))%")
                        .titleMedium()
                        .foregroundColor(Color.theme.primary)
                        .fontWeight(.bold)
                    
                    Text("completion")
                        .labelMedium()
                        .foregroundColor(Color.theme.textSecondary)
                }
            }
            
            // Weekly stats
            HStack(spacing: .spacing.lg) {
                WeekStatItem(
                    title: "Avg Calories",
                    value: "\(weeklyProgress.averageCalories)",
                    color: Color.theme.primary
                )
                
                WeekStatItem(
                    title: "Total Protein",
                    value: "\(Int(weeklyProgress.totalProtein))g",
                    color: Color.theme.secondary
                )
                
                WeekStatItem(
                    title: "Days Tracked",
                    value: "\(weeklyProgress.dailyProgresses.filter { !$0.analyses.isEmpty }.count)",
                    color: Color.theme.success
                )
            }
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct MonthlyOverviewCard: View {
    let monthlyProgress: MonthlyProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing.xs) {
                    Text("This Month")
                        .titleMedium()
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text("Monthly nutrition trends")
                        .labelMedium()
                        .foregroundColor(Color.theme.textSecondary)
                }
                
                Spacer()
                
                // Streak badge
                if monthlyProgress.streak > 0 {
                    HStack(spacing: .spacing.xs) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color.theme.warning)
                        
                        Text("\(monthlyProgress.streak)")
                            .titleMedium()
                            .foregroundColor(Color.theme.warning)
                            .fontWeight(.bold)
                    }
                }
            }
            
            // Monthly chart placeholder
            BarChartView(
                data: monthlyProgress.weeklyProgresses.map { week in
                    ChartDataPoint(
                        label: "W\(Calendar.current.component(.weekOfYear, from: week.weekStart))",
                        value: Double(week.averageCalories)
                    )
                },
                title: "Weekly Calorie Average",
                color: Color.theme.primary
            )
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct WeekStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: .spacing.xs) {
            Text(value)
                .titleMedium()
                .foregroundColor(color)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)
        }
    }
}

struct MotivationalTipCard: View {
    private let tips = [
        "🥗 Fill half your plate with vegetables for balanced nutrition",
        "💧 Drink water before meals to help with portion control",
        "🏃‍♂️ Pair your nutrition goals with regular physical activity",
        "😴 Good sleep helps regulate hunger hormones",
        "📱 Log your meals as you eat for better tracking accuracy"
    ]
    
    @State private var currentTipIndex = 0
    
    var body: some View {
        VStack(spacing: .spacing.md) {
            HStack {
                Text("Daily Tip")
                    .titleMedium()
                    .foregroundColor(Color.theme.textPrimary)
                
                Spacer()
                
                Button(action: nextTip) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color.theme.primary)
                }
            }
            
            Text(tips[currentTipIndex])
                .bodyMedium()
                .foregroundColor(Color.theme.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.theme.primary.opacity(0.05), Color.theme.secondary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                        .strokeBorder(Color.theme.primary.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            // Show different tip based on day of year
            currentTipIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0 % tips.count
        }
    }
    
    private func nextTip() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTipIndex = (currentTipIndex + 1) % tips.count
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .labelMedium()
                    .foregroundColor(Color.theme.textPrimary)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .cardPadding()
            .background(
                RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                    .fill(Color.theme.surface)
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: .spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.theme.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: .spacing.xs) {
                Text(title)
                    .titleMedium()
                    .foregroundColor(Color.theme.textPrimary)
                    .fontWeight(.semibold)
                
                Text(description)
                    .bodyMedium()
                    .foregroundColor(Color.theme.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success, error
        
        var color: Color {
            switch self {
            case .success: return Color.theme.success
            case .error: return Color.theme.error
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: .spacing.sm) {
            Image(systemName: type.icon)
                .foregroundColor(.white)
            
            Text(message)
                .bodyMedium(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(type.color)
                .shadow(radius: 10)
        )
        .containerPadding()
    }
}

#Preview {
    EnhancedGoalsView()
}