import Foundation
import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var analyses: [FoodAnalysisResponse] = []
    @Published var filteredAnalyses: [FoodAnalysisResponse] = []
    @Published var analyticsData: AnalyticsData = .empty
    @Published var searchText: String = ""
    @Published var selectedDateRange: DateRange = .thisWeek
    @Published var isLoading = false
    @Published var showExportSheet = false
    @Published var selectedExportFormat: ExportFormat = .json
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Filter and Sort Options
    @Published var sortOption: SortOption = .dateDescending
    @Published var filterByHealthScore: HealthScoreFilter = .all
    @Published var showOnlyFavorites = false
    
    // Analytics
    @Published var showAnalytics = false
    @Published var selectedAnalyticsPeriod: AnalyticsPeriod = .thisMonth
    
    // MARK: - Dependencies
    private let historyRepository: HistoryRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var totalAnalyses: Int {
        analyses.count
    }
    
    var averageCaloriesThisWeek: Int {
        let thisWeekAnalyses = analyses.filter { Calendar.current.isDate($0.analysisDate, equalTo: Date(), toGranularity: .weekOfYear) }
        guard !thisWeekAnalyses.isEmpty else { return 0 }
        return thisWeekAnalyses.reduce(0) { $0 + $1.calories } / thisWeekAnalyses.count
    }
    
    var healthyChoicesPercentage: Double {
        guard !analyses.isEmpty else { return 0 }
        let healthyCount = analyses.filter { $0.healthScore.lowercased().contains("healthy") }.count
        return Double(healthyCount) / Double(analyses.count) * 100
    }
    
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    // MARK: - Initialization
    init(historyRepository: HistoryRepositoryProtocol = HistoryRepository()) {
        self.historyRepository = historyRepository
        setupBindings()
        loadAnalyses()
        loadAnalytics()
    }
    
    // MARK: - Public Methods
    func loadAnalyses() {
        isLoading = true
        
        switch historyRepository.getAllAnalyses() {
        case .success(let loadedAnalyses):
            analyses = loadedAnalyses
            applyFiltersAndSort()
        case .failure(let error):
            showError(error)
        }
        
        isLoading = false
    }
    
    func searchAnalyses() {
        guard !searchText.isEmpty else {
            applyFiltersAndSort()
            return
        }
        
        switch historyRepository.searchAnalyses(query: searchText) {
        case .success(let searchResults):
            analyses = searchResults
            applyFiltersAndSort()
        case .failure(let error):
            showError(error)
        }
    }
    
    func filterByDateRange() {
        switch historyRepository.getAnalyses(for: selectedDateRange) {
        case .success(let filteredAnalyses):
            analyses = filteredAnalyses
            applyFiltersAndSort()
        case .failure(let error):
            showError(error)
        }
    }
    
    func deleteAnalysis(_ analysis: FoodAnalysisResponse) {
        switch historyRepository.deleteAnalysis(withId: analysis.id) {
        case .success:
            loadAnalyses() // Refresh the list
            loadAnalytics() // Update analytics
        case .failure(let error):
            showError(error)
        }
    }
    
    func exportAnalyses() {
        switch historyRepository.exportAnalyses(format: selectedExportFormat) {
        case .success(let data):
            shareExportedData(data)
        case .failure(let error):
            showError(error)
        }
    }
    
    func refreshAnalytics() {
        loadAnalytics()
    }
    
    func clearSearch() {
        searchText = ""
        loadAnalyses()
    }
    
    func toggleFavorites() {
        showOnlyFavorites.toggle()
        applyFiltersAndSort()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // React to search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.searchAnalyses()
            }
            .store(in: &cancellables)
        
        // React to filter changes
        Publishers.CombineLatest3($sortOption, $filterByHealthScore, $showOnlyFavorites)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        // React to date range changes
        $selectedDateRange
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.filterByDateRange()
            }
            .store(in: &cancellables)
        
        // Listen to repository updates
        historyRepository.analysesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedAnalyses in
                self?.analyses = updatedAnalyses
                self?.applyFiltersAndSort()
                self?.loadAnalytics()
            }
            .store(in: &cancellables)
        
        // Auto-hide errors after 5 seconds
        $showError
            .filter { $0 }
            .delay(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.clearError()
            }
            .store(in: &cancellables)
    }
    
    private func applyFiltersAndSort() {
        var filtered = analyses
        
        // Apply health score filter
        switch filterByHealthScore {
        case .healthy:
            filtered = filtered.filter { $0.healthScore.lowercased().contains("healthy") }
        case .good:
            filtered = filtered.filter { $0.healthScore.lowercased().contains("good") }
        case .needsImprovement:
            filtered = filtered.filter { 
                !$0.healthScore.lowercased().contains("healthy") && 
                !$0.healthScore.lowercased().contains("good")
            }
        case .all:
            break
        }
        
        // Apply favorites filter (assuming we add a favorites system later)
        if showOnlyFavorites {
            // filtered = filtered.filter { $0.isFavorite }
        }
        
        // Apply sorting
        switch sortOption {
        case .dateDescending:
            filtered.sort { $0.analysisDate > $1.analysisDate }
        case .dateAscending:
            filtered.sort { $0.analysisDate < $1.analysisDate }
        case .caloriesHighToLow:
            filtered.sort { $0.calories > $1.calories }
        case .caloriesLowToHigh:
            filtered.sort { $0.calories < $1.calories }
        case .healthScoreBest:
            filtered.sort { $0.healthScoreValue > $1.healthScoreValue }
        case .alphabetical:
            filtered.sort { $0.itemName.localizedCaseInsensitiveCompare($1.itemName) == .orderedAscending }
        }
        
        filteredAnalyses = filtered
    }
    
    private func loadAnalytics() {
        switch historyRepository.getAnalyticsData() {
        case .success(let analytics):
            analyticsData = analytics
        case .failure(let error):
            showError(error)
        }
    }
    
    private func shareExportedData(_ data: Data) {
        let filename = "food_analysis_export_\(Date().timeIntervalSince1970)"
        let fileExtension = selectedExportFormat == .json ? "json" : "csv"
        
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filename).\(fileExtension)")
        
        do {
            try data.write(to: tempURL)
            
            // Share using UIActivityViewController
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // Get the current window scene and present
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Handle iPad presentation
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            showError(.storage(.encodingFailed))
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let dayAnalyses = analyses.filter { calendar.isDate($0.analysisDate, inSameDayAs: currentDate) }
            
            if dayAnalyses.isEmpty {
                break
            }
            
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
            
            // Cap at 365 days
            if streak >= 365 { break }
        }
        
        return streak
    }
    
    private func showError(_ error: AppError) {
        errorMessage = error.userFriendlyMessage
        showError = true
    }
    
    private func clearError() {
        errorMessage = nil
        showError = false
    }
}

// MARK: - Supporting Types
enum SortOption: String, CaseIterable {
    case dateDescending = "Latest First"
    case dateAscending = "Oldest First"
    case caloriesHighToLow = "Most Calories"
    case caloriesLowToHigh = "Least Calories"
    case healthScoreBest = "Healthiest First"
    case alphabetical = "A to Z"
    
    var icon: String {
        switch self {
        case .dateDescending, .dateAscending:
            return "calendar"
        case .caloriesHighToLow, .caloriesLowToHigh:
            return "flame"
        case .healthScoreBest:
            return "heart"
        case .alphabetical:
            return "textformat.abc"
        }
    }
}

enum HealthScoreFilter: String, CaseIterable {
    case all = "All"
    case healthy = "Healthy"
    case good = "Good"
    case needsImprovement = "Needs Improvement"
    
    var color: Color {
        switch self {
        case .all:
            return Color.theme.textSecondary
        case .healthy:
            return Color.theme.success
        case .good:
            return Color.theme.primary
        case .needsImprovement:
            return Color.theme.warning
        }
    }
}

enum AnalyticsPeriod: String, CaseIterable {
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case allTime = "All Time"
    
    var dateRange: DateRange {
        switch self {
        case .thisWeek:
            return .thisWeek
        case .thisMonth:
            return .thisMonth
        case .last30Days:
            return .last30Days
        case .last90Days:
            let calendar = Calendar.current
            let now = Date()
            let start = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            return .custom(start: start, end: now)
        case .allTime:
            let distantPast = Date(timeIntervalSince1970: 0)
            return .custom(start: distantPast, end: Date())
        }
    }
}
