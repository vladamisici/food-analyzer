import SwiftUI

// MARK: - DateRange Extensions for Hashable/Equatable
extension DateRange: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(startDate)
        hasher.combine(endDate)
    }
    
    static func == (lhs: DateRange, rhs: DateRange) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.endDate == rhs.endDate
    }
}

struct EnhancedHistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showSearchBar = false
    @State private var showFilterSheet = false
    @State private var showAnalyticsSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredAnalyses.isEmpty {
                    emptyStateView
                } else {
                    mainContent
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showAnalyticsSheet = true }) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(Color.theme.primary)
                    }
                    
                    Button(action: { showSearchBar.toggle() }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.theme.primary)
                    }
                    
                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Color.theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .sheet(isPresented: $showAnalyticsSheet) {
                analyticsSheet
            }
            .refreshable {
                viewModel.loadAnalyses()
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Search bar
            if showSearchBar {
                searchBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Quick stats
            quickStatsBar
            
            // Analyses list
            analysesList
        }
        .animation(.easeInOut(duration: 0.3), value: showSearchBar)
    }
    
    private var searchBar: some View {
        HStack(spacing: .spacing.md) {
            HStack(spacing: .spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.theme.textSecondary)
                
                TextField("Search food, comments, or health scores...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: viewModel.clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, .spacing.md)
            .padding(.vertical, .spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                    .fill(Color.theme.surface)
            )
            
            Button("Cancel") {
                showSearchBar = false
                viewModel.clearSearch()
            }
            .labelMedium(Color.theme.primary)
        }
        .containerPadding()
        .background(Color.theme.background)
    }
    
    private var quickStatsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing.md) {
                StatCard(
                    title: "Total",
                    value: "\(viewModel.totalAnalyses)",
                    icon: "list.bullet",
                    color: Color.theme.primary
                )
                
                StatCard(
                    title: "This Week",
                    value: "\(viewModel.averageCaloriesThisWeek)",
                    subtitle: "avg calories",
                    icon: "flame.fill",
                    color: Color.theme.secondary
                )
                
                StatCard(
                    title: "Healthy",
                    value: "\(Int(viewModel.healthyChoicesPercentage))%",
                    icon: "heart.fill",
                    color: Color.theme.success
                )
                
                StatCard(
                    title: "Streak",
                    value: "\(viewModel.currentStreak)",
                    subtitle: "days",
                    icon: "flame",
                    color: Color.theme.warning
                )
            }
            .padding(.horizontal, .spacing.containerPadding)
        }
        .padding(.vertical, .spacing.md)
    }
    
    private var analysesList: some View {
        ScrollView {
            LazyVStack(spacing: .spacing.md) {
                ForEach(viewModel.filteredAnalyses) { analysis in
                    HistoryAnalysisCard(
                        analysis: analysis,
                        onDelete: { viewModel.deleteAnalysis(analysis) }
                    )
                    .containerPadding()
                }
            }
            .padding(.vertical, .spacing.md)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: .spacing.xl) {
            // Illustration
            ZStack {
                Circle()
                    .fill(Color.theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(Color.theme.primary.opacity(0.6))
            }
            
            VStack(spacing: .spacing.md) {
                Text("No Analysis History")
                    .headlineMedium()
                    .foregroundColor(Color.theme.textPrimary)
                
                Text("Start analyzing your food to see your nutrition history here. Every meal is a step towards your goals!")
                    .bodyMedium()
                    .foregroundColor(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .containerPadding()
            }
            
            PrimaryButton("Analyze Your First Meal", style: .primary) {
                // Navigate to camera/analysis view
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
            
            Text("Loading your history...")
                .bodyMedium()
                .foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationView {
            VStack(spacing: .spacing.xl) {
                // Date Range Filter
                VStack(alignment: .leading, spacing: .spacing.md) {
                    Text("Date Range")
                        .titleMedium()
                        .foregroundColor(Color.theme.textPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.sm) {
                        let ranges = [DateRange.today, .thisWeek, .thisMonth, .last30Days]
                        ForEach(Array(ranges.enumerated()), id: \.offset) { index, range in
                            FilterOptionButton(
                                title: range.displayName,
                                isSelected: isDateRangeSelected(range)
                            ) {
                                viewModel.selectedDateRange = range
                            }
                        }
                    }
                }
                
                // Sort Options
                VStack(alignment: .leading, spacing: .spacing.md) {
                    Text("Sort By")
                        .titleMedium()
                        .foregroundColor(Color.theme.textPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.sm) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            FilterOptionButton(
                                title: option.rawValue,
                                icon: option.icon,
                                isSelected: viewModel.sortOption == option
                            ) {
                                viewModel.sortOption = option
                            }
                        }
                    }
                }
                
                // Health Score Filter
                VStack(alignment: .leading, spacing: .spacing.md) {
                    Text("Health Score")
                        .titleMedium()
                        .foregroundColor(Color.theme.textPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.sm) {
                        ForEach(HealthScoreFilter.allCases, id: \.self) { filter in
                            FilterOptionButton(
                                title: filter.rawValue,
                                isSelected: viewModel.filterByHealthScore == filter,
                                color: filter.color
                            ) {
                                viewModel.filterByHealthScore = filter
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: .spacing.md) {
                    PrimaryButton("Reset", style: .secondary) {
                        viewModel.selectedDateRange = .thisWeek
                        viewModel.sortOption = .dateDescending
                        viewModel.filterByHealthScore = .all
                    }
                    
                    PrimaryButton("Apply Filters", style: .primary) {
                        showFilterSheet = false
                    }
                }
                .containerPadding()
            }
            .containerPadding()
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilterSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Analytics Sheet
    private var analyticsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: .spacing.xl) {
                    // Analytics period selector
                    Picker("Period", selection: $viewModel.selectedAnalyticsPeriod) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .containerPadding()
                    
                    // Charts and analytics
                    if viewModel.analyticsData.totalAnalyses > 0 {
                        analyticsContent
                    } else {
                        emptyAnalyticsView
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: viewModel.exportAnalyses) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button("Done") {
                        showAnalyticsSheet = false
                    }
                }
            }
        }
    }
    
    private var analyticsContent: some View {
        VStack(spacing: .spacing.xl) {
            // Overview stats
            overviewStatsGrid
            
            // Charts
            chartsSection
            
            // Top foods
            topFoodsSection
        }
    }
    
    private var overviewStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.md) {
            AnalyticsStatCard(
                title: "Total Analyses",
                value: "\(viewModel.analyticsData.totalAnalyses)",
                icon: "list.bullet",
                color: Color.theme.primary
            )
            
            AnalyticsStatCard(
                title: "Avg Calories",
                value: "\(Int(viewModel.analyticsData.averageCaloriesPerDay))",
                icon: "flame.fill",
                color: Color.theme.secondary
            )
            
            AnalyticsStatCard(
                title: "Avg Protein",
                value: "\(Int(viewModel.analyticsData.averageProtein))g",
                icon: "bolt.fill",
                color: Color.theme.success
            )
            
            AnalyticsStatCard(
                title: "Health Score",
                value: "\(String(format: "%.1f", viewModel.analyticsData.averageHealthScore))",
                icon: "heart.fill",
                color: Color.theme.accent
            )
        }
        .containerPadding()
    }
    
    private var chartsSection: some View {
        VStack(spacing: .spacing.lg) {
            // Calorie trend chart
            if !viewModel.analyticsData.caloriesTrend.isEmpty {
                LineChartView(
                    data: viewModel.analyticsData.caloriesTrend.map { trend in
                        ChartDataPoint(
                            label: formatDateLabel(trend.date),
                            value: Double(trend.calories)
                        )
                    },
                    title: "Calorie Trends"
                )
                .containerPadding()
            }
            
            // Nutrition breakdown chart
            DonutChartView(
                data: [
                    DonutChartSegment(
                        label: "Protein",
                        value: viewModel.analyticsData.nutritionBreakdown.proteinPercentage,
                        color: Color.theme.success
                    ),
                    DonutChartSegment(
                        label: "Fat",
                        value: viewModel.analyticsData.nutritionBreakdown.fatPercentage,
                        color: Color.theme.primary
                    ),
                    DonutChartSegment(
                        label: "Carbs",
                        value: viewModel.analyticsData.nutritionBreakdown.carbsPercentage,
                        color: Color.theme.warning
                    )
                ],
                title: "Nutrition Breakdown",
                centerText: "Macros"
            )
            .containerPadding()
        }
    }
    
    private var topFoodsSection: some View {
        VStack(alignment: .leading, spacing: .spacing.md) {
            Text("Most Analyzed Foods")
                .titleMedium()
                .foregroundColor(Color.theme.textPrimary)
                .containerPadding()
            
            VStack(spacing: .spacing.sm) {
                ForEach(Array(viewModel.analyticsData.mostFrequentFoods.enumerated()), id: \.offset) { index, food in
                    HStack {
                        // Rank
                        ZStack {
                            Circle()
                                .fill(rankColor(for: index))
                                .frame(width: 24, height: 24)
                            
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        // Food name
                        Text(food.capitalized)
                            .bodyMedium()
                            .foregroundColor(Color.theme.textPrimary)
                        
                        Spacer()
                        
                        // Medal for top 3
                        if index < 3 {
                            Image(systemName: medalIcon(for: index))
                                .foregroundColor(rankColor(for: index))
                        }
                    }
                    .containerPadding()
                    .background(
                        RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                            .fill(Color.theme.surface)
                    )
                }
            }
            .containerPadding()
        }
    }
    
    private var emptyAnalyticsView: some View {
        VStack(spacing: .spacing.lg) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(Color.theme.textTertiary)
            
            Text("No Analytics Available")
                .titleMedium()
                .foregroundColor(Color.theme.textSecondary)
            
            Text("Analyze more foods to see detailed analytics and insights")
                .bodyMedium()
                .foregroundColor(Color.theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .containerPadding()
    }
    
    // MARK: - Helper Methods
    
    private func isDateRangeSelected(_ range: DateRange) -> Bool {
        return viewModel.selectedDateRange.startDate == range.startDate &&
               viewModel.selectedDateRange.endDate == range.endDate
    }
    
    private func formatDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return Color.theme.primary
        }
    }
    
    private func medalIcon(for index: Int) -> String {
        switch index {
        case 0: return "medal.fill"
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        default: return ""
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: .spacing.xs) {
            HStack(spacing: .spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
            
            Text(value)
                .titleMedium()
                .foregroundColor(Color.theme.textPrimary)
                .fontWeight(.semibold)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color.theme.textTertiary)
            }
        }
        .frame(width: 80)
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.black.opacity(0.03),
                    radius: 4,
                    x: 0,
                    y: 1
                )
        )
    }
}

struct FilterOptionButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, color: Color = Color.theme.primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(title)
                    .labelMedium()
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: .spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: .spacing.xs) {
                Text(value)
                    .titleLarge()
                    .foregroundColor(Color.theme.textPrimary)
                    .fontWeight(.bold)
                
                Text(title)
                    .labelMedium()
                    .foregroundColor(Color.theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

struct HistoryAnalysisCard: View {
    let analysis: FoodAnalysisResponse
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: .spacing.md) {
            // Header with food name and date
            HStack {
                VStack(alignment: .leading, spacing: .spacing.xs) {
                    Text(analysis.itemName)
                        .titleMedium()
                        .foregroundColor(Color.theme.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text(formatAnalysisDate(analysis.analysisDate))
                        .labelMedium()
                        .foregroundColor(Color.theme.textSecondary)
                }
                
                Spacer()
                
                // Health score badge
                HStack(spacing: .spacing.xs) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                    
                    Text(analysis.healthScore)
                        .labelMedium()
                        .fontWeight(.medium)
                }
                .foregroundColor(healthScoreColor(analysis.healthScore))
                .padding(.horizontal, .spacing.sm)
                .padding(.vertical, .spacing.xs)
                .background(
                    Capsule()
                        .fill(healthScoreColor(analysis.healthScore).opacity(0.15))
                )
            }
            
            // Macros overview
            HStack(spacing: .spacing.lg) {
                MacroStat(label: "Calories", value: "\(analysis.calories)", color: Color.theme.primary)
                MacroStat(label: "Protein", value: analysis.protein, color: Color.theme.secondary)
                MacroStat(label: "Carbs", value: analysis.carbs, color: Color.theme.warning)
                MacroStat(label: "Fat", value: analysis.fat, color: Color.theme.accent)
            }
            
            // Coach comment
            if !analysis.coachComment.isEmpty {
                HStack(spacing: .spacing.sm) {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(Color.theme.primary)
                        .font(.caption)
                    
                    Text(analysis.coachComment)
                        .bodyMedium()
                        .foregroundColor(Color.theme.textSecondary)
                        .lineLimit(2)
                    
                    Spacer()
                }
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
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: { showDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Analysis", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this food analysis? This action cannot be undone.")
        }
    }
    
    private func formatAnalysisDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func healthScoreColor(_ score: String) -> Color {
        switch score.lowercased() {
        case let s where s.contains("healthy") || s.contains("excellent"):
            return Color.theme.success
        case let s where s.contains("good"):
            return Color.theme.primary
        case let s where s.contains("fair") || s.contains("moderate"):
            return Color.theme.warning
        default:
            return Color.theme.error
        }
    }
}

struct MacroStat: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: .spacing.xs) {
            Text(value)
                .labelMedium()
                .foregroundColor(color)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.theme.textTertiary)
        }
    }
}

// MARK: - Extensions
extension DateRange {
    var displayName: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            return "Today"
        } else if calendar.isDate(startDate, equalTo: Date().startOfWeek, toGranularity: .day) {
            return "This Week"
        } else if calendar.isDate(startDate, equalTo: Date().startOfMonth, toGranularity: .day) {
            return "This Month"
        } else if calendar.dateComponents([.day], from: startDate, to: Date()).day == 30 {
            return "Last 30 Days"
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
}

#Preview {
    EnhancedHistoryView()
}
