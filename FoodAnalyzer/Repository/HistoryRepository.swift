import Foundation
import Combine

// MARK: - History Repository Protocol
protocol HistoryRepositoryProtocol {
    func saveAnalysis(_ analysis: FoodAnalysisResponse) -> AppResult<Void>
    func getAllAnalyses() -> AppResult<[FoodAnalysisResponse]>
    func getAnalyses(for dateRange: DateRange) -> AppResult<[FoodAnalysisResponse]>
    func searchAnalyses(query: String) -> AppResult<[FoodAnalysisResponse]>
    func deleteAnalysis(withId id: String) -> AppResult<Void>
    func getAnalyticsData() -> AppResult<AnalyticsData>
    func exportAnalyses(format: ExportFormat) -> AppResult<Data>
    
    // Reactive updates
    var analysesPublisher: AnyPublisher<[FoodAnalysisResponse], Never> { get }
}

// MARK: - History Repository Implementation
final class HistoryRepository: HistoryRepositoryProtocol {
    private let userDefaults = UserDefaults.standard
    private let analysesKey = "saved_food_analyses"
    private let maxStoredAnalyses = 1000
    
    private let analysesSubject = CurrentValueSubject<[FoodAnalysisResponse], Never>([])
    
    var analysesPublisher: AnyPublisher<[FoodAnalysisResponse], Never> {
        analysesSubject.eraseToAnyPublisher()
    }
    
    init() {
        loadAnalysesFromStorage()
    }
    
    // MARK: - Core Operations
    func saveAnalysis(_ analysis: FoodAnalysisResponse) -> AppResult<Void> {
        var analyses = analysesSubject.value
        
        // Remove duplicate if exists
        analyses.removeAll { $0.id == analysis.id }
        
        // Add new analysis at the beginning
        analyses.insert(analysis, at: 0)
        
        // Limit storage size
        if analyses.count > maxStoredAnalyses {
            analyses = Array(analyses.prefix(maxStoredAnalyses))
        }
        
        return saveAnalysesToStorage(analyses)
    }
    
    func getAllAnalyses() -> AppResult<[FoodAnalysisResponse]> {
        return .success(analysesSubject.value)
    }
    
    func getAnalyses(for dateRange: DateRange) -> AppResult<[FoodAnalysisResponse]> {
        let filtered = analysesSubject.value.filter { analysis in
            let date = analysis.analysisDate
            return date >= dateRange.startDate && date <= dateRange.endDate
        }
        return .success(filtered)
    }
    
    func searchAnalyses(query: String) -> AppResult<[FoodAnalysisResponse]> {
        guard !query.isEmpty else {
            return getAllAnalyses()
        }
        
        let filtered = analysesSubject.value.filter { analysis in
            analysis.itemName.localizedCaseInsensitiveContains(query) ||
            analysis.coachComment.localizedCaseInsensitiveContains(query) ||
            analysis.healthScore.localizedCaseInsensitiveContains(query)
        }
        
        return .success(filtered)
    }
    
    func deleteAnalysis(withId id: String) -> AppResult<Void> {
        var analyses = analysesSubject.value
        analyses.removeAll { $0.id == id }
        return saveAnalysesToStorage(analyses)
    }
    
    // MARK: - Analytics
    func getAnalyticsData() -> AppResult<AnalyticsData> {
        let analyses = analysesSubject.value
        
        guard !analyses.isEmpty else {
            return .success(AnalyticsData.empty)
        }
        
        let totalAnalyses = analyses.count
        let totalCalories = analyses.reduce(0) { $0 + $1.calories }
        let averageCalories = totalCalories / totalAnalyses
        
        let totalProtein = analyses.reduce(0.0) { $0 + $1.proteinValue }
        let totalFat = analyses.reduce(0.0) { $0 + $1.fatValue }
        let totalCarbs = analyses.reduce(0.0) { $0 + $1.carbsValue }
        
        let averageProtein = totalProtein / Double(totalAnalyses)
        let averageFat = totalFat / Double(totalAnalyses)
        let averageCarbs = totalCarbs / Double(totalAnalyses)
        
        // Health score distribution
        let healthyCount = analyses.filter { $0.healthScore.lowercased().contains("healthy") }.count
        let goodCount = analyses.filter { $0.healthScore.lowercased().contains("good") }.count
        let fairCount = analyses.filter { $0.healthScore.lowercased().contains("fair") }.count
        let poorCount = totalAnalyses - healthyCount - goodCount - fairCount
        
        // Most frequent foods
        let foodFrequency = Dictionary(grouping: analyses, by: { $0.itemName.lowercased() })
        let topFoods = foodFrequency
            .map { (food: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0.food }
        
        // Weekly trends
        let weeklyData = calculateWeeklyTrends(analyses)
        
        let analytics = AnalyticsData(
            totalAnalyses: totalAnalyses,
            averageCalories: averageCalories,
            averageProtein: averageProtein,
            averageFat: averageFat,
            averageCarbs: averageCarbs,
            healthScoreDistribution: HealthScoreDistribution(
                healthy: healthyCount,
                good: goodCount,
                fair: fairCount,
                poor: poorCount
            ),
            topFoods: Array(topFoods),
            weeklyTrends: weeklyData,
            lastUpdated: Date()
        )
        
        return .success(analytics)
    }
    
    // MARK: - Export
    func exportAnalyses(format: ExportFormat) -> AppResult<Data> {
        let analyses = analysesSubject.value
        
        switch format {
        case .json:
            return exportAsJSON(analyses)
        case .csv:
            return exportAsCSV(analyses)
        }
    }
    
    // MARK: - Private Methods
    private func loadAnalysesFromStorage() {
        guard let data = userDefaults.data(forKey: analysesKey),
              let analyses = try? JSONDecoder().decode([FoodAnalysisResponse].self, from: data) else {
            analysesSubject.send([])
            return
        }
        
        analysesSubject.send(analyses)
    }
    
    private func saveAnalysesToStorage(_ analyses: [FoodAnalysisResponse]) -> AppResult<Void> {
        do {
            let data = try JSONEncoder().encode(analyses)
            userDefaults.set(data, forKey: analysesKey)
            analysesSubject.send(analyses)
            return .success(())
        } catch {
            return .failure(.storage(.encodingFailed))
        }
    }
    
    private func calculateWeeklyTrends(_ analyses: [FoodAnalysisResponse]) -> [WeeklyTrend] {
        let calendar = Calendar.current
        let now = Date()
        let fourWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -4, to: now) ?? now
        
        let recentAnalyses = analyses.filter { $0.analysisDate >= fourWeeksAgo }
        
        let weeklyGroups = Dictionary(grouping: recentAnalyses) { analysis in
            calendar.component(.weekOfYear, from: analysis.analysisDate)
        }
        
        return weeklyGroups.map { (week, analyses) in
            let totalCalories = analyses.reduce(0) { $0 + $1.calories }
            let avgCalories = analyses.isEmpty ? 0 : totalCalories / analyses.count
            
            return WeeklyTrend(
                week: week,
                analysisCount: analyses.count,
                averageCalories: avgCalories,
                averageProtein: analyses.reduce(0.0) { $0 + $1.proteinValue } / Double(analyses.count),
                averageFat: analyses.reduce(0.0) { $0 + $1.fatValue } / Double(analyses.count),
                averageCarbs: analyses.reduce(0.0) { $0 + $1.carbsValue } / Double(analyses.count)
            )
        }.sorted { $0.week < $1.week }
    }
    
    private func exportAsJSON(_ analyses: [FoodAnalysisResponse]) -> AppResult<Data> {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(analyses)
            return .success(data)
        } catch {
            return .failure(.storage(.encodingFailed))
        }
    }
    
    private func exportAsCSV(_ analyses: [FoodAnalysisResponse]) -> AppResult<Data> {
        var csvContent = "Date,Food Name,Calories,Protein,Fat,Carbs,Health Score,Coach Comment\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        for analysis in analyses {
            let escapedName = analysis.itemName.replacingOccurrences(of: ",", with: ";")
            let escapedComment = analysis.coachComment.replacingOccurrences(of: ",", with: ";")
            
            csvContent += "\(formatter.string(from: analysis.analysisDate)),\(escapedName),\(analysis.calories),\(analysis.protein),\(analysis.fat),\(analysis.carbs),\(analysis.healthScore),\(escapedComment)\n"
        }
        
        guard let data = csvContent.data(using: .utf8) else {
            return .failure(.storage(.encodingFailed))
        }
        
        return .success(data)
    }
}

// MARK: - Supporting Types
enum DateRange: Hashable, Equatable {
    case today
    case thisWeek
    case thisMonth
    case last30Days
    case custom(start: Date, end: Date)
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .custom(let start, _):
            return start
        }
    }
    
    var endDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.end ?? now
        case .last30Days:
            return now
        case .custom(_, let end):
            return end
        }
    }
}

enum ExportFormat {
    case json
    case csv
}

struct AnalyticsData: Codable {
    let totalAnalyses: Int
    let averageCalories: Int
    let averageProtein: Double
    let averageFat: Double
    let averageCarbs: Double
    let healthScoreDistribution: HealthScoreDistribution
    let topFoods: [String]
    let weeklyTrends: [WeeklyTrend]
    let lastUpdated: Date
    
    static let empty = AnalyticsData(
        totalAnalyses: 0,
        averageCalories: 0,
        averageProtein: 0,
        averageFat: 0,
        averageCarbs: 0,
        healthScoreDistribution: HealthScoreDistribution(healthy: 0, good: 0, fair: 0, poor: 0),
        topFoods: [],
        weeklyTrends: [],
        lastUpdated: Date()
    )
}

struct HealthScoreDistribution: Codable {
    let healthy: Int
    let good: Int
    let fair: Int
    let poor: Int
}

struct WeeklyTrend: Codable {
    let week: Int
    let analysisCount: Int
    let averageCalories: Int
    let averageProtein: Double
    let averageFat: Double
    let averageCarbs: Double
}