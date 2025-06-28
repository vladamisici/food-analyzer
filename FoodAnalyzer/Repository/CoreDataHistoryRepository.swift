import Foundation
import CoreData
import Combine

// MARK: - Missing Supporting Types
struct DateRange {
    let startDate: Date
    let endDate: Date
    
    // Custom initializer for creating date ranges with start and end dates
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // Static method for custom date ranges
    static func custom(start: Date, end: Date) -> DateRange {
        return DateRange(startDate: start, endDate: end)
    }
    
    static var today: DateRange {
        let now = Date()
        return DateRange(startDate: now.startOfDay, endDate: now.endOfDay)
    }
    
    static var thisWeek: DateRange {
        let now = Date()
        let startOfWeek = now.startOfWeek
        let endOfWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
        return DateRange(startDate: startOfWeek, endDate: endOfWeek)
    }
    
    static var thisMonth: DateRange {
        let now = Date()
        let startOfMonth = now.startOfMonth
        let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
        return DateRange(startDate: startOfMonth, endDate: endOfMonth)
    }
    
    // Missing static property for last 30 days
    static var last30Days: DateRange {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        return DateRange(startDate: start, endDate: now)
    }
    
    // Additional useful date ranges
    static var yesterday: DateRange {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        return DateRange(startDate: yesterday.startOfDay, endDate: yesterday.endOfDay)
    }
    
    static var lastWeek: DateRange {
        let calendar = Calendar.current
        let now = Date()
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: now.startOfWeek) ?? now
        let lastWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastWeekStart) ?? now
        return DateRange(startDate: lastWeekStart, endDate: lastWeekEnd.endOfDay)
    }
    
    static var lastMonth: DateRange {
        let calendar = Calendar.current
        let now = Date()
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: now.startOfMonth) ?? now
        let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: now.startOfMonth) ?? now
        return DateRange(startDate: lastMonthStart, endDate: lastMonthEnd.endOfDay)
    }
    
    // Computed properties for convenience
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var daysCount: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(components.day ?? 0, 1)
    }
    
    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(startDate) && calendar.isDateInToday(endDate)
    }
    
    var isThisWeek: Bool {
        let calendar = Calendar.current
        return calendar.isDate(startDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var isThisMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(startDate, equalTo: Date(), toGranularity: .month)
    }
    
    // Helper method to check if a date falls within this range
    func contains(_ date: Date) -> Bool {
        return date >= startDate && date <= endDate
    }
    
    // Helper method to format the date range for display
    func displayString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return formatter.string(from: startDate)
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
}

struct AnalyticsData {
    let totalAnalyses: Int
    let averageCaloriesPerDay: Double
    let averageProtein: Double
    let averageFat: Double
    let averageCarbs: Double
    let averageHealthScore: Double
    let mostFrequentFoods: [String]
    let caloriesTrend: [CalorieDataPoint]
    let nutritionBreakdown: NutritionBreakdown
    let weeklyStats: WeeklyStats
    
    struct CalorieDataPoint {
        let date: Date
        let calories: Int
    }
    
    struct NutritionBreakdown {
        let proteinPercentage: Double
        let fatPercentage: Double
        let carbsPercentage: Double
        
        static let empty = NutritionBreakdown(
            proteinPercentage: 0.0,
            fatPercentage: 0.0,
            carbsPercentage: 0.0
        )
    }
    
    struct WeeklyStats {
        let totalCalories: Int
        let averageCalories: Int
        let healthScoreImprovement: Double
        
        static let empty = WeeklyStats(
            totalCalories: 0,
            averageCalories: 0,
            healthScoreImprovement: 0.0
        )
    }
    
    static let empty = AnalyticsData(
        totalAnalyses: 0,
        averageCaloriesPerDay: 0.0,
        averageProtein: 0.0,
        averageFat: 0.0,
        averageCarbs: 0.0,
        averageHealthScore: 0.0,
        mostFrequentFoods: [],
        caloriesTrend: [],
        nutritionBreakdown: NutritionBreakdown.empty,
        weeklyStats: WeeklyStats.empty
    )
}

enum ExportFormat {
    case csv
    case json
    case pdf
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        }
    }
    
    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        case .pdf: return "application/pdf"
        }
    }
}

// MARK: - Fixed CoreDataHistoryRepository
class CoreDataHistoryRepository: HistoryRepositoryProtocol {
    private let coreDataManager = CoreDataManager.shared
    private let currentUserSubject = CurrentValueSubject<User?, Never>(nil)
    private let analysesSubject = CurrentValueSubject<[FoodAnalysisResponse], Never>([])
    
    var currentUser: User? {
        get { currentUserSubject.value }
        set {
            currentUserSubject.send(newValue)
            loadAnalyses() // Reload when user changes
        }
    }
    
    var analysesPublisher: AnyPublisher<[FoodAnalysisResponse], Never> {
        analysesSubject.eraseToAnyPublisher()
    }
    
    init() {
        loadAnalyses()
    }
    
    // MARK: - Protocol Implementation
    func saveAnalysis(_ analysis: FoodAnalysisResponse) -> AppResult<Void> {
        guard let userId = currentUser?.id else {
            return .failure(.authentication(.unauthorized))
        }
        
        do {
            let context = coreDataManager.viewContext
            _ = FoodAnalysisEntity.from(analysis, userId: userId, imageData: nil, in: context)
            try context.save()
            
            // Update publisher
            loadAnalyses()
            
            return .success(())
        } catch {
            return .failure(.storage(.encodingFailed))
        }
    }
    
    func getAllAnalyses() -> AppResult<[FoodAnalysisResponse]> {
        guard let userId = currentUser?.id else {
            return .failure(.authentication(.unauthorized))
        }
        
        do {
            let context = coreDataManager.viewContext
            let request = FoodAnalysisEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(request)
            let analyses = entities.compactMap { $0.toFoodAnalysisResponse() }
            
            return .success(analyses)
        } catch {
            return .failure(.storage(.decodingFailed))
        }
    }
    
    func getAnalyses(for dateRange: DateRange) -> AppResult<[FoodAnalysisResponse]> {
        guard let userId = currentUser?.id else {
            return .failure(.authentication(.unauthorized))
        }
        
        do {
            let context = coreDataManager.viewContext
            let request = FoodAnalysisEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "userId == %@ AND createdAt >= %@ AND createdAt <= %@",
                userId, dateRange.startDate as NSDate, dateRange.endDate as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(request)
            let analyses = entities.compactMap { $0.toFoodAnalysisResponse() }
            
            return .success(analyses)
        } catch {
            return .failure(.storage(.decodingFailed))
        }
    }
    
    func searchAnalyses(query: String) -> AppResult<[FoodAnalysisResponse]> {
        guard let userId = currentUser?.id else {
            return .failure(.authentication(.unauthorized))
        }
        
        do {
            let context = coreDataManager.viewContext
            let request = FoodAnalysisEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "userId == %@ AND itemName CONTAINS[cd] %@",
                userId, query
            )
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(request)
            let analyses = entities.compactMap { $0.toFoodAnalysisResponse() }
            
            return .success(analyses)
        } catch {
            return .failure(.storage(.decodingFailed))
        }
    }
    
    func deleteAnalysis(withId id: String) -> AppResult<Void> {
        guard let userId = currentUser?.id else {
            return .failure(.authentication(.unauthorized))
        }
        
        do {
            let context = coreDataManager.viewContext
            let request = FoodAnalysisEntity.fetchRequest()
            request.predicate = NSPredicate(format: "analysisId == %@ AND userId == %@", id, userId)
            
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
                
                // Update publisher
                loadAnalyses()
                
                return .success(())
            } else {
                return .failure(.storage(.keyNotFound))
            }
        } catch {
            return .failure(.storage(.decodingFailed))
        }
    }
    
    func getAnalyticsData() -> AppResult<AnalyticsData> {
        switch getAllAnalyses() {
        case .success(let analyses):
            let analytics = calculateAnalytics(from: analyses)
            return .success(analytics)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func exportAnalyses(format: ExportFormat) -> AppResult<Data> {
        switch getAllAnalyses() {
        case .success(let analyses):
            return exportData(analyses: analyses, format: format)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Private Helper Methods
    private func loadAnalyses() {
        switch getAllAnalyses() {
        case .success(let analyses):
            analysesSubject.send(analyses)
        case .failure:
            analysesSubject.send([])
        }
    }
    
    private func calculateAnalytics(from analyses: [FoodAnalysisResponse]) -> AnalyticsData {
        guard !analyses.isEmpty else {
            return AnalyticsData(
                totalAnalyses: 0,
                averageCaloriesPerDay: 0,
                averageProtein: 0,
                averageFat: 0,
                averageCarbs: 0,
                averageHealthScore: 0,
                mostFrequentFoods: [],
                caloriesTrend: [],
                nutritionBreakdown: AnalyticsData.NutritionBreakdown(
                    proteinPercentage: 0,
                    fatPercentage: 0,
                    carbsPercentage: 0
                ),
                weeklyStats: AnalyticsData.WeeklyStats(
                    totalCalories: 0,
                    averageCalories: 0,
                    healthScoreImprovement: 0
                )
            )
        }
        
        let totalCalories = analyses.reduce(0) { $0 + $1.calories }
        let averageCalories = Double(totalCalories) / Double(analyses.count)
        
        let avgProtein = analyses.reduce(0.0) { $0 + $1.proteinValue } / Double(analyses.count)
        let avgFat = analyses.reduce(0.0) { $0 + $1.fatValue } / Double(analyses.count)
        let avgCarbs = analyses.reduce(0.0) { $0 + $1.carbsValue } / Double(analyses.count)
        let avgHealthScore = analyses.reduce(0.0) { $0 + Double($1.healthScoreValue) } / Double(analyses.count)
        
        // Most frequent foods
        let foodCounts = Dictionary(grouping: analyses) { $0.itemName }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        let mostFrequentFoods = Array(foodCounts.prefix(5).map { $0.key })
        
        // Calories trend (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentAnalyses = analyses.filter { $0.analysisDate >= thirtyDaysAgo }
        let caloriesTrend = createCaloriesTrend(from: recentAnalyses)
        
        // Nutrition breakdown
        let totalMacros = avgProtein + avgFat + avgCarbs
        let nutritionBreakdown = AnalyticsData.NutritionBreakdown(
            proteinPercentage: totalMacros > 0 ? (avgProtein / totalMacros) * 100 : 0,
            fatPercentage: totalMacros > 0 ? (avgFat / totalMacros) * 100 : 0,
            carbsPercentage: totalMacros > 0 ? (avgCarbs / totalMacros) * 100 : 0
        )
        
        // Weekly stats
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let weeklyAnalyses = analyses.filter { $0.analysisDate >= weekAgo }
        let weeklyCalories = weeklyAnalyses.reduce(0) { $0 + $1.calories }
        let weeklyAverage = weeklyAnalyses.isEmpty ? 0 : weeklyCalories / weeklyAnalyses.count
        
        return AnalyticsData(
            totalAnalyses: analyses.count,
            averageCaloriesPerDay: averageCalories,
            averageProtein: avgProtein,
            averageFat: avgFat,
            averageCarbs: avgCarbs,
            averageHealthScore: avgHealthScore,
            mostFrequentFoods: mostFrequentFoods,
            caloriesTrend: caloriesTrend,
            nutritionBreakdown: nutritionBreakdown,
            weeklyStats: AnalyticsData.WeeklyStats(
                totalCalories: weeklyCalories,
                averageCalories: weeklyAverage,
                healthScoreImprovement: 0 // Could calculate trend
            )
        )
    }
    
    private func createCaloriesTrend(from analyses: [FoodAnalysisResponse]) -> [AnalyticsData.CalorieDataPoint] {
        let groupedByDate = Dictionary(grouping: analyses) { analysis in
            Calendar.current.startOfDay(for: analysis.analysisDate)
        }
        
        return groupedByDate.map { date, dayAnalyses in
            let totalCalories = dayAnalyses.reduce(0) { $0 + $1.calories }
            return AnalyticsData.CalorieDataPoint(date: date, calories: totalCalories)
        }.sorted { $0.date < $1.date }
    }
    
    private func exportData(analyses: [FoodAnalysisResponse], format: ExportFormat) -> AppResult<Data> {
        switch format {
        case .csv:
            return exportCSV(analyses: analyses)
        case .json:
            return exportJSON(analyses: analyses)
        case .pdf:
            return .failure(.unknown("PDF export not implemented"))
        }
    }
    
    private func exportCSV(analyses: [FoodAnalysisResponse]) -> AppResult<Data> {
        var csv = "Date,Food,Calories,Protein,Fat,Carbs,Health Score\n"
        
        for analysis in analyses {
            let row = "\(analysis.analysisDate.formattedAs("yyyy-MM-dd")),\(analysis.itemName),\(analysis.calories),\(analysis.proteinValue),\(analysis.fatValue),\(analysis.carbsValue),\(analysis.healthScore)\n"
            csv += row
        }
        
        guard let data = csv.data(using: .utf8) else {
            return .failure(.storage(.encodingFailed))
        }
        
        return .success(data)
    }
    
    private func exportJSON(analyses: [FoodAnalysisResponse]) -> AppResult<Data> {
        do {
            let data = try JSONEncoder().encode(analyses)
            return .success(data)
        } catch {
            return .failure(.storage(.encodingFailed))
        }
    }
}
