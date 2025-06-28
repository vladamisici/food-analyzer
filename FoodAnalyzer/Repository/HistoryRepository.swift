import Foundation
import UIKit
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
        
        // Calculate average health score
        let totalHealthScore = analyses.reduce(0.0) { $0 + Double($1.healthScoreValue) }
        let averageHealthScore = totalHealthScore / Double(totalAnalyses)
        
        // Calculate average calories per day
        let uniqueDays = Set(analyses.map { Calendar.current.startOfDay(for: $0.analysisDate) })
        let averageCaloriesPerDay = uniqueDays.isEmpty ? 0.0 : Double(totalCalories) / Double(uniqueDays.count)
        
        // Most frequent foods
        let foodFrequency = Dictionary(grouping: analyses, by: { $0.itemName.lowercased() })
        let mostFrequentFoods = foodFrequency
            .map { (food: $0.key.capitalized, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0.food }
        
        // Create calories trend data points
        let caloriesTrend = createCaloriesTrend(from: analyses)
        
        // Calculate nutrition breakdown percentages
        let totalMacros = averageProtein + averageFat + averageCarbs
        let nutritionBreakdown = AnalyticsData.NutritionBreakdown(
            proteinPercentage: totalMacros > 0 ? (averageProtein / totalMacros) * 100 : 0,
            fatPercentage: totalMacros > 0 ? (averageFat / totalMacros) * 100 : 0,
            carbsPercentage: totalMacros > 0 ? (averageCarbs / totalMacros) * 100 : 0
        )
        
        // Calculate weekly stats
        let weeklyStats = calculateWeeklyStats(from: analyses)
        
        let analytics = AnalyticsData(
            totalAnalyses: totalAnalyses,
            averageCaloriesPerDay: averageCaloriesPerDay,
            averageProtein: averageProtein,
            averageFat: averageFat,
            averageCarbs: averageCarbs,
            averageHealthScore: averageHealthScore,
            mostFrequentFoods: Array(mostFrequentFoods),
            caloriesTrend: caloriesTrend,
            nutritionBreakdown: nutritionBreakdown,
            weeklyStats: weeklyStats
        )
        
        return .success(analytics)
    }

    // MARK: - Helper Methods for Analytics
    private func createCaloriesTrend(from analyses: [FoodAnalysisResponse]) -> [AnalyticsData.CalorieDataPoint] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Filter to last 30 days
        let recentAnalyses = analyses.filter { $0.analysisDate >= thirtyDaysAgo }
        
        // Group by date
        let groupedByDate = Dictionary(grouping: recentAnalyses) { analysis in
            calendar.startOfDay(for: analysis.analysisDate)
        }
        
        // Create data points
        return groupedByDate.map { date, dayAnalyses in
            let totalCalories = dayAnalyses.reduce(0) { $0 + $1.calories }
            return AnalyticsData.CalorieDataPoint(date: date, calories: totalCalories)
        }.sorted { $0.date < $1.date }
    }

    private func calculateWeeklyStats(from analyses: [FoodAnalysisResponse]) -> AnalyticsData.WeeklyStats {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        
        // Filter to this week
        let weeklyAnalyses = analyses.filter { $0.analysisDate >= weekAgo }
        
        let totalCalories = weeklyAnalyses.reduce(0) { $0 + $1.calories }
        let averageCalories = weeklyAnalyses.isEmpty ? 0 : totalCalories / weeklyAnalyses.count
        
        // Calculate health score improvement (compare to previous week)
        let twoWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -2, to: now) ?? now
        let previousWeekAnalyses = analyses.filter {
            $0.analysisDate >= twoWeeksAgo && $0.analysisDate < weekAgo
        }
        
        let currentWeekHealthScore = weeklyAnalyses.isEmpty ? 0.0 :
            weeklyAnalyses.reduce(0.0) { $0 + Double($1.healthScoreValue) } / Double(weeklyAnalyses.count)
        let previousWeekHealthScore = previousWeekAnalyses.isEmpty ? 0.0 :
            previousWeekAnalyses.reduce(0.0) { $0 + Double($1.healthScoreValue) } / Double(previousWeekAnalyses.count)
        
        let healthScoreImprovement = currentWeekHealthScore - previousWeekHealthScore
        
        return AnalyticsData.WeeklyStats(
            totalCalories: totalCalories,
            averageCalories: averageCalories,
            healthScoreImprovement: healthScoreImprovement
        )
    }
    
    // MARK: - Export
    func exportAnalyses(format: ExportFormat) -> AppResult<Data> {
        let analyses = analysesSubject.value
        
        guard !analyses.isEmpty else {
            return .failure(.storage(.keyNotFound))
        }
        
        switch format {
        case .json:
            return exportAsJSON(analyses)
        case .csv:
            return exportAsCSV(analyses)
        case .pdf:
            return exportAsPDF(analyses)
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
    
    private func exportAsPDF(_ analyses: [FoodAnalysisResponse]) -> AppResult<Data> {
        // Create PDF document
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // US Letter size
        
        do {
            let pdfData = pdfRenderer.pdfData { context in
                var currentY: CGFloat = 50
                let pageHeight: CGFloat = 792
                let pageWidth: CGFloat = 612
                let margin: CGFloat = 50
                let contentWidth = pageWidth - (margin * 2)
                
                // Start first page
                context.beginPage()
                
                // Title
                currentY = drawTitle(in: context, at: currentY, pageWidth: pageWidth)
                currentY += 30
                
                // Summary Statistics
                currentY = drawSummaryStats(analyses, in: context, at: currentY, margin: margin, contentWidth: contentWidth)
                currentY += 40
                
                // Table Header
                currentY = drawTableHeader(in: context, at: currentY, margin: margin, contentWidth: contentWidth)
                currentY += 25
                
                // Analyses Data
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                
                for (index, analysis) in analyses.enumerated() {
                    // Check if we need a new page
                    if currentY > pageHeight - 100 {
                        context.beginPage()
                        currentY = 50
                        
                        // Redraw header on new page
                        currentY = drawTableHeader(in: context, at: currentY, margin: margin, contentWidth: contentWidth)
                        currentY += 25
                    }
                    
                    currentY = drawAnalysisRow(
                        analysis: analysis,
                        index: index,
                        dateFormatter: dateFormatter,
                        in: context,
                        at: currentY,
                        margin: margin,
                        contentWidth: contentWidth
                    )
                    currentY += 20
                }
                
                // Footer
                if currentY < pageHeight - 60 {
                    drawFooter(in: context, pageHeight: pageHeight, pageWidth: pageWidth)
                }
            }
            
            return .success(pdfData)
        } catch {
            return .failure(.storage(.encodingFailed))
        }
    }

    // MARK: - PDF Drawing Helper Methods
    private func drawTitle(in context: UIGraphicsPDFRendererContext, at y: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let titleText = "Food Analysis Report"
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let titleSize = titleText.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (pageWidth - titleSize.width) / 2,
            y: y,
            width: titleSize.width,
            height: titleSize.height
        )
        
        titleText.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Draw line under title
        let lineY = y + titleSize.height + 10
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.move(to: CGPoint(x: 50, y: lineY))
        context.cgContext.addLine(to: CGPoint(x: pageWidth - 50, y: lineY))
        context.cgContext.strokePath()
        
        return lineY + 10
    }

    private func drawSummaryStats(_ analyses: [FoodAnalysisResponse], in context: UIGraphicsPDFRendererContext, at y: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let summaryFont = UIFont.systemFont(ofSize: 12)
        let summaryBoldFont = UIFont.boldSystemFont(ofSize: 12)
        let lineHeight: CGFloat = 16
        var currentY = y
        
        // Calculate summary statistics
        let totalAnalyses = analyses.count
        let totalCalories = analyses.reduce(0) { $0 + $1.calories }
        let avgCalories = totalAnalyses > 0 ? totalCalories / totalAnalyses : 0
        let avgProtein = totalAnalyses > 0 ? analyses.reduce(0.0) { $0 + $1.proteinValue } / Double(totalAnalyses) : 0
        let avgFat = totalAnalyses > 0 ? analyses.reduce(0.0) { $0 + $1.fatValue } / Double(totalAnalyses) : 0
        let avgCarbs = totalAnalyses > 0 ? analyses.reduce(0.0) { $0 + $1.carbsValue } / Double(totalAnalyses) : 0
        
        let dateRange = analyses.isEmpty ? "No data" :
            "\(analyses.map { $0.analysisDate }.min()?.formattedAs("MMM d, yyyy") ?? "") - \(analyses.map { $0.analysisDate }.max()?.formattedAs("MMM d, yyyy") ?? "")"
        
        let summaryLines = [
            ("Report Date:", Date().formattedAs("MMM d, yyyy 'at' h:mm a")),
            ("Date Range:", dateRange),
            ("Total Analyses:", "\(totalAnalyses)"),
            ("Average Calories:", "\(avgCalories) cal"),
            ("Average Protein:", String(format: "%.1fg", avgProtein)),
            ("Average Fat:", String(format: "%.1fg", avgFat)),
            ("Average Carbs:", String(format: "%.1fg", avgCarbs))
        ]
        
        for (label, value) in summaryLines {
            // Draw label
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: summaryBoldFont,
                .foregroundColor: UIColor.black
            ]
            label.draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttributes)
            
            // Draw value
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: summaryFont,
                .foregroundColor: UIColor.black
            ]
            value.draw(at: CGPoint(x: margin + 120, y: currentY), withAttributes: valueAttributes)
            
            currentY += lineHeight
        }
        
        return currentY
    }

    private func drawTableHeader(in context: UIGraphicsPDFRendererContext, at y: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let headerFont = UIFont.boldSystemFont(ofSize: 10)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white
        ]
        
        // Draw header background
        let headerRect = CGRect(x: margin, y: y, width: contentWidth, height: 20)
        context.cgContext.setFillColor(UIColor.darkGray.cgColor)
        context.cgContext.fill(headerRect)
        
        // Header columns
        let headers = ["Date", "Food", "Calories", "Protein", "Fat", "Carbs", "Health"]
        let columnWidths: [CGFloat] = [80, 140, 60, 50, 50, 50, 82] // Total: 512
        
        var currentX = margin + 5
        for (index, header) in headers.enumerated() {
            let headerSize = header.size(withAttributes: headerAttributes)
            header.draw(at: CGPoint(x: currentX, y: y + 5), withAttributes: headerAttributes)
            currentX += columnWidths[index]
        }
        
        return y + 20
    }

    private func drawAnalysisRow(analysis: FoodAnalysisResponse, index: Int, dateFormatter: DateFormatter, in context: UIGraphicsPDFRendererContext, at y: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let cellFont = UIFont.systemFont(ofSize: 9)
        let cellAttributes: [NSAttributedString.Key: Any] = [
            .font: cellFont,
            .foregroundColor: UIColor.black
        ]
        
        // Alternating row colors
        if index % 2 == 0 {
            let rowRect = CGRect(x: margin, y: y, width: contentWidth, height: 18)
            context.cgContext.setFillColor(UIColor.lightGray.withAlphaComponent(0.1).cgColor)
            context.cgContext.fill(rowRect)
        }
        
        // Data for each column
        let rowData = [
            dateFormatter.string(from: analysis.analysisDate),
            truncateText(analysis.itemName, maxLength: 20),
            "\(analysis.calories)",
            analysis.protein,
            analysis.fat,
            analysis.carbs,
            truncateText(analysis.healthScore, maxLength: 12)
        ]
        
        let columnWidths: [CGFloat] = [80, 140, 60, 50, 50, 50, 82]
        
        var currentX = margin + 5
        for (index, data) in rowData.enumerated() {
            data.draw(at: CGPoint(x: currentX, y: y + 2), withAttributes: cellAttributes)
            currentX += columnWidths[index]
        }
        
        // Draw row border
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: margin, y: y + 18))
        context.cgContext.addLine(to: CGPoint(x: margin + contentWidth, y: y + 18))
        context.cgContext.strokePath()
        
        return y + 18
    }

    private func drawFooter(in context: UIGraphicsPDFRendererContext, pageHeight: CGFloat, pageWidth: CGFloat) {
        let footerFont = UIFont.systemFont(ofSize: 8)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = "Generated by Food Analyzer • \(Date().formattedAs("MMM d, yyyy"))"
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerRect = CGRect(
            x: (pageWidth - footerSize.width) / 2,
            y: pageHeight - 30,
            width: footerSize.width,
            height: footerSize.height
        )
        
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }

    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength - 3)) + "..."
    }

    // MARK: - Alternative Simple PDF Export (if you prefer a simpler approach)
    private func exportAsPDFSimple(_ analyses: [FoodAnalysisResponse]) -> AppResult<Data> {
        // Create a simple text-based PDF
        let pageSize = CGSize(width: 612, height: 792) // US Letter
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            let margin: CGFloat = 50
            let lineHeight: CGFloat = 20
            
            // Title
            let title = "Food Analysis Export"
            let titleFont = UIFont.boldSystemFont(ofSize: 20)
            let titleAttributes = [NSAttributedString.Key.font: titleFont]
            
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += lineHeight * 2
            
            // Date
            let dateText = "Generated: \(Date().formattedAs("MMM d, yyyy 'at' h:mm a"))"
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let bodyAttributes = [NSAttributedString.Key.font: bodyFont]
            
            dateText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += lineHeight * 2
            
            // Analyses
            for analysis in analyses.prefix(30) { // Limit to first 30 for simple version
                if yPosition > pageSize.height - 100 {
                    context.beginPage()
                    yPosition = 50
                }
                
                let analysisText = """
                \(analysis.analysisDate.formattedAs("MMM d, yyyy h:mm a"))
                Food: \(analysis.itemName)
                Calories: \(analysis.calories) | Protein: \(analysis.protein) | Fat: \(analysis.fat) | Carbs: \(analysis.carbs)
                Health Score: \(analysis.healthScore)
                """
                
                analysisText.draw(
                    in: CGRect(x: margin, y: yPosition, width: pageSize.width - margin * 2, height: lineHeight * 4),
                    withAttributes: bodyAttributes
                )
                
                yPosition += lineHeight * 5
            }
        }
        
        return .success(pdfData)
    }
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
