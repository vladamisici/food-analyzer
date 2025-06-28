import Foundation
import UIKit

// MARK: - Validation Error
enum ValidationError: Error, LocalizedError {
    case invalidEmail
    case weakPassword
    case emptyFields
    case userNotFound
    case emailAlreadyExists
    case networkError
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters with letters and numbers"
        case .emptyFields:
            return "Please fill in all required fields"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .networkError:
            return "Network connection error"
        case .invalidCredentials:
            return "Invalid email or password"
        }
    }
}

// MARK: - Enhanced User Model
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let createdAt: Date?
    let profileImageURL: String?
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    // Validation
    static func validate(email: String, password: String, firstName: String, lastName: String) -> ValidationError? {
        if !email.isValidEmail {
            return .invalidEmail
        }
        if !password.isValidPassword {
            return .weakPassword
        }
        if firstName.isEmpty || lastName.isEmpty {
            return .emptyFields
        }
        return nil
    }
}

// MARK: - Enhanced Auth Models
struct AuthResponse: Codable {
    let token: String
    let user: User
    let expiresAt: Date?
}

struct LoginRequest: Codable {
    let email: String
    let password: String
    
    func validate() -> ValidationError? {
        if email.isEmpty || password.isEmpty {
            return .emptyFields
        }
        if !email.isValidEmail {
            return .invalidEmail
        }
        return nil
    }
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    
    func validate() -> ValidationError? {
        return User.validate(email: email, password: password, firstName: firstName, lastName: lastName)
    }
}

// MARK: - Enhanced Food Analysis Models
struct FoodAnalysisRequest: Codable {
    let image: String
    let compressionQuality: Double?
    let metadata: ImageMetadata?
    
    struct ImageMetadata: Codable {
        let size: CGSize
        let originalSize: Int
        let compressedSize: Int
    }
}

struct FoodAnalysisResponse: Codable, Identifiable, Equatable {
    let id: String
    var itemName: String
    var calories: Int
    let protein: String  // API returns as string like "10g"
    let fat: String      // API returns as string like "18g"
    let carbs: String    // API returns as string like "20g"
    let healthScore: String    // API returns as string like "Healthy"
    let coachComment: String
    let analyzedAt: String     // API returns as ISO date string
    
    // MARK: - Enhanced Computed Properties for Robust Parsing
    var proteinValue: Double {
        return parseNutrientValue(from: protein)
    }
    
    var fatValue: Double {
        return parseNutrientValue(from: fat)
    }
    
    var carbsValue: Double {
        return parseNutrientValue(from: carbs)
    }
    
    // MARK: - Private Helper for Robust Nutrient Parsing
    private func parseNutrientValue(from string: String) -> Double {
        // Handle various formats: "25g", "25.5g", "25 g", "25.5 grams", "25", etc.
        let cleanString = string.lowercased()
            .replacingOccurrences(of: "grams", with: "")
            .replacingOccurrences(of: "gram", with: "")
            .replacingOccurrences(of: "g", with: "")
            .trimmingCharacters(in: .whitespacesAndPunctuation)
        
        // Extract numeric value using regex for better accuracy
        let numericString = cleanString.replacingOccurrences(
            of: "[^0-9.]",
            with: "",
            options: .regularExpression
        )
        
        return Double(numericString) ?? 0.0
    }
    
    var healthScoreValue: Int {
        // Convert "Healthy" to a numeric score for compatibility
        switch healthScore.lowercased() {
        case "healthy", "excellent": return 9
        case "good": return 7
        case "fair", "moderate": return 5
        case "poor": return 3
        default: return 5
        }
    }
    
    var analysisDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: analyzedAt) ?? Date()
    }
    
    // MARK: - Enhanced Nutrition Analysis
    var isHighProtein: Bool {
        return proteinValue >= 20.0
    }
    
    var isLowCarb: Bool {
        return carbsValue <= 20.0
    }
    
    var isLowFat: Bool {
        return fatValue <= 10.0
    }
    
    var isBalanced: Bool {
        let totalMacros = proteinValue + fatValue + carbsValue
        guard totalMacros > 0 else { return false }
        
        let proteinRatio = proteinValue / totalMacros
        let fatRatio = fatValue / totalMacros
        let carbRatio = carbsValue / totalMacros
        
        // Balanced if no macro dominates excessively
        return proteinRatio <= 0.6 && fatRatio <= 0.6 && carbRatio <= 0.6
    }
    
    // MARK: - Macro Distribution
    var macroDistribution: MacroDistribution {
        let totalMacros = proteinValue + fatValue + carbsValue
        guard totalMacros > 0 else {
            return MacroDistribution(protein: 0, fat: 0, carbs: 0)
        }
        
        return MacroDistribution(
            protein: (proteinValue / totalMacros) * 100,
            fat: (fatValue / totalMacros) * 100,
            carbs: (carbsValue / totalMacros) * 100
        )
    }
    
    struct MacroDistribution: Codable {
        let protein: Double  // Percentage
        let fat: Double      // Percentage
        let carbs: Double    // Percentage
        
        var dominantMacro: String {
            if protein >= fat && protein >= carbs {
                return "Protein"
            } else if fat >= carbs {
                return "Fat"
            } else {
                return "Carbs"
            }
        }
    }
    
    // Enhanced features with defaults
    var fiber: Double? { nil }
    var sugar: Double? { nil }
    var sodium: Double? { nil }
    var confidence: Double { 0.9 }
    var imageURL: String? { nil }
    var nutritionGrade: NutritionGrade { calculateNutritionGrade() }
    var macroBreakdown: MacroBreakdown {
        MacroBreakdown(
            proteinPercentage: proteinValue,
            fatPercentage: fatValue,
            carbsPercentage: carbsValue
        )
    }
    var insights: [NutritionInsight] { generateInsights() }
    
    // MARK: - Dynamic Nutrition Grade Calculation
    private func calculateNutritionGrade() -> NutritionGrade {
        var score = 0
        
        // Points for balanced macros
        if isBalanced { score += 2 }
        
        // Points for adequate protein
        if proteinValue >= 15 { score += 2 }
        else if proteinValue >= 10 { score += 1 }
        
        // Points for moderate fat
        if fatValue <= 15 { score += 2 }
        else if fatValue <= 25 { score += 1 }
        
        // Points for reasonable calories
        if calories <= 500 { score += 2 }
        else if calories <= 800 { score += 1 }
        
        // Points for health score
        if healthScoreValue >= 8 { score += 2 }
        else if healthScoreValue >= 6 { score += 1 }
        
        switch score {
        case 9...10: return .excellent
        case 7...8: return .good
        case 5...6: return .fair
        case 3...4: return .poor
        default: return .veryPoor
        }
    }
    
    // MARK: - Dynamic Insights Generation
    private func generateInsights() -> [NutritionInsight] {
        var insights: [NutritionInsight] = []
        
        // High protein insight
        if isHighProtein {
            insights.append(NutritionInsight(
                type: .goodProtein,
                message: "Great protein content! Helps with muscle maintenance and satiety.",
                severity: .positive
            ))
        } else if proteinValue < 10 {
            insights.append(NutritionInsight(
                type: .lowProtein,
                message: "Consider adding more protein to this meal for better nutrition balance.",
                severity: .warning
            ))
        }
        
        // Fat content insight
        if fatValue > 30 {
            insights.append(NutritionInsight(
                type: .highFat,
                message: "High fat content. Consider pairing with vegetables or lighter sides.",
                severity: .warning
            ))
        }
        
        // Calorie insight
        if calories > 600 {
            insights.append(NutritionInsight(
                type: .highCalorie,
                message: "High calorie food. Great for active days or post-workout meals.",
                severity: .info
            ))
        }
        
        // Balanced meal insight
        if isBalanced {
            insights.append(NutritionInsight(
                type: .balanced,
                message: "Well-balanced macro distribution! This supports sustained energy.",
                severity: .positive
            ))
        }
        
        return insights
    }
    
    struct MacroBreakdown: Codable, Equatable {
        let proteinPercentage: Double
        let fatPercentage: Double
        let carbsPercentage: Double
        
        var totalGrams: Double {
            return proteinPercentage + fatPercentage + carbsPercentage
        }
    }
    
    struct NutritionInsight: Codable, Identifiable, Equatable {
        let id = UUID()
        let type: InsightType
        let message: String
        let severity: Severity
        
        enum InsightType: String, Codable, CaseIterable {
            case highSodium = "high_sodium"
            case lowProtein = "low_protein"
            case goodProtein = "good_protein"
            case highFat = "high_fat"
            case highCalorie = "high_calorie"
            case highSugar = "high_sugar"
            case goodFiber = "good_fiber"
            case balanced = "balanced"
        }
        
        enum Severity: String, Codable {
            case info, warning, positive
            
            var color: String {
                switch self {
                case .info: return "blue"
                case .warning: return "orange"
                case .positive: return "green"
                }
            }
            
            var icon: String {
                switch self {
                case .info: return "info.circle"
                case .warning: return "exclamationmark.triangle"
                case .positive: return "checkmark.circle"
                }
            }
        }
    }
    
    enum NutritionGrade: String, Codable, CaseIterable {
        case excellent = "A+"
        case good = "A"
        case fair = "B"
        case poor = "C"
        case veryPoor = "D"
        
        var color: String {
            switch self {
            case .excellent, .good: return "green"
            case .fair: return "orange"
            case .poor, .veryPoor: return "red"
            }
        }
        
        var description: String {
            switch self {
            case .excellent: return "Excellent nutritional choice!"
            case .good: return "Good nutritional value"
            case .fair: return "Moderate nutritional value"
            case .poor: return "Low nutritional value"
            case .veryPoor: return "Very low nutritional value"
            }
        }
        
        var emoji: String {
            switch self {
            case .excellent: return "🌟"
            case .good: return "✅"
            case .fair: return "⚠️"
            case .poor: return "❌"
            case .veryPoor: return "💀"
            }
        }
    }
    
    // Calculate total calories from macros for validation
    var calculatedCalories: Int {
        Int((proteinValue * 4) + (fatValue * 9) + (carbsValue * 4))
    }
    
    // Health score color
    var healthScoreColor: String {
        switch healthScore.lowercased() {
        case "healthy", "excellent": return "green"
        case "good": return "orange"
        case "fair", "moderate": return "yellow"
        default: return "red"
        }
    }
    
    // MARK: - Formatted Display Values
    var formattedProtein: String {
        return String(format: "%.1fg", proteinValue)
    }
    
    var formattedFat: String {
        return String(format: "%.1fg", fatValue)
    }
    
    var formattedCarbs: String {
        return String(format: "%.1fg", carbsValue)
    }
    
    var formattedCalories: String {
        return "\(calories) cal"
    }
}

// MARK: - Analysis History Model
struct AnalysisHistory: Codable, Identifiable {
    let id = UUID()
    let analyses: [FoodAnalysisResponse]
    let totalAnalyses: Int
    let averageHealthScore: Double
    let favoriteFood: String?
    let totalCalories: Int
    let createdAt: Date
    
    var weeklyAverage: Double {
        guard !analyses.isEmpty else { return 0 }
        return Double(totalCalories) / 7.0
    }
    
    var averageCaloriesPerMeal: Double {
        guard !analyses.isEmpty else { return 0 }
        return Double(totalCalories) / Double(analyses.count)
    }
    
    var macroAverages: (protein: Double, fat: Double, carbs: Double) {
        guard !analyses.isEmpty else { return (0, 0, 0) }
        
        let totalProtein = analyses.reduce(0) { $0 + $1.proteinValue }
        let totalFat = analyses.reduce(0) { $0 + $1.fatValue }
        let totalCarbs = analyses.reduce(0) { $0 + $1.carbsValue }
        let count = Double(analyses.count)
        
        return (
            protein: totalProtein / count,
            fat: totalFat / count,
            carbs: totalCarbs / count
        )
    }
}

// MARK: - Nutrition Goals Model
struct NutritionGoals: Codable, Identifiable {
    var id = UUID()
    var dailyCalorieGoal: Int
    var proteinGoal: Double
    var fatGoal: Double
    var carbsGoal: Double
    var fiberGoal: Double
    var activityLevel: ActivityLevel
    var goals: [Goal]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary, lightly, moderately, very, extremely
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightly: return 1.375
            case .moderately: return 1.55
            case .very: return 1.725
            case .extremely: return 1.9
            }
        }
        
        var description: String {
            switch self {
            case .sedentary: return "Sedentary (little or no exercise)"
            case .lightly: return "Lightly active (light exercise 1-3 days/week)"
            case .moderately: return "Moderately active (moderate exercise 3-5 days/week)"
            case .very: return "Very active (hard exercise 6-7 days/week)"
            case .extremely: return "Extremely active (very hard exercise, physical job)"
            }
        }
        
        var emoji: String {
            switch self {
            case .sedentary: return "🛋️"
            case .lightly: return "🚶‍♂️"
            case .moderately: return "🏃‍♂️"
            case .very: return "🏋️‍♂️"
            case .extremely: return "🔥"
            }
        }
    }
    
    struct Goal: Codable, Identifiable {
        let id = UUID()
        let type: GoalType
        let target: Double
        let current: Double
        let deadline: Date?
        let createdAt: Date = Date()
        
        enum GoalType: String, Codable, CaseIterable {
            case weightLoss = "weight_loss"
            case weightGain = "weight_gain"
            case maintenance = "maintenance"
            case muscle = "muscle_gain"
            case endurance = "endurance"
            
            var displayName: String {
                switch self {
                case .weightLoss: return "Weight Loss"
                case .weightGain: return "Weight Gain"
                case .maintenance: return "Weight Maintenance"
                case .muscle: return "Muscle Gain"
                case .endurance: return "Endurance Training"
                }
            }
            
            var emoji: String {
                switch self {
                case .weightLoss: return "📉"
                case .weightGain: return "📈"
                case .maintenance: return "⚖️"
                case .muscle: return "💪"
                case .endurance: return "🏃‍♂️"
                }
            }
            
            var description: String {
                switch self {
                case .weightLoss: return "Focus on creating a caloric deficit while maintaining muscle mass"
                case .weightGain: return "Focus on healthy weight gain with proper nutrition"
                case .maintenance: return "Maintain current weight with balanced nutrition"
                case .muscle: return "Build muscle mass with adequate protein and strength training"
                case .endurance: return "Fuel endurance activities with proper carbohydrate intake"
                }
            }
        }
        
        var progress: Double {
            guard target > 0 else { return 0 }
            return min(current / target, 1.0)
        }
        
        var isCompleted: Bool {
            return progress >= 1.0
        }
        
        var remainingDays: Int? {
            guard let deadline = deadline else { return nil }
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: Date(), to: deadline).day ?? 0
            return max(days, 0)
        }
    }
    
    // Computed properties for easier access
    var hasActiveGoals: Bool {
        return !goals.isEmpty
    }
    
    var completedGoalsCount: Int {
        return goals.filter { $0.isCompleted }.count
    }
    
    var totalGoalsCount: Int {
        return goals.count
    }
    
    var overallProgress: Double {
        guard !goals.isEmpty else { return 0 }
        let totalProgress = goals.reduce(0) { $0 + $1.progress }
        return totalProgress / Double(goals.count)
    }
}

// MARK: - Progress Tracking Models
struct DailyProgress: Codable {
    var date: Date
    var analyses: [FoodAnalysisResponse]
    var totalCalories: Int
    var totalProtein: Double
    var totalFat: Double
    var totalCarbs: Double
    var calorieProgress: Double
    var proteinProgress: Double
    var fatProgress: Double
    var carbsProgress: Double
    var lastUpdated: Date
    
    static let empty = DailyProgress(
        date: Date(),
        analyses: [],
        totalCalories: 0,
        totalProtein: 0,
        totalFat: 0,
        totalCarbs: 0,
        calorieProgress: 0,
        proteinProgress: 0,
        fatProgress: 0,
        carbsProgress: 0,
        lastUpdated: Date()
    )
    
    var isGoalMet: Bool {
        return calorieProgress >= 0.9 && calorieProgress <= 1.1 &&
               proteinProgress >= 0.9 && fatProgress >= 0.9 && carbsProgress >= 0.9
    }
    
    var mealsCount: Int {
        return analyses.count
    }
    
    var averageHealthScore: Double {
        guard !analyses.isEmpty else { return 0 }
        let totalScore = analyses.reduce(0) { $0 + $1.healthScoreValue }
        return Double(totalScore) / Double(analyses.count)
    }
}

struct WeeklyProgress: Codable {
    let weekStart: Date
    var dailyProgresses: [DailyProgress]
    var totalCalories: Int
    var totalProtein: Double
    var totalFat: Double
    var totalCarbs: Double
    var averageCalories: Int
    var goalCompletionRate: Double
    
    var daysWithProgress: Int {
        return dailyProgresses.filter { !$0.analyses.isEmpty }.count
    }
    
    var consistency: Double {
        return Double(daysWithProgress) / 7.0
    }
}

struct MonthlyProgress: Codable {
    let monthStart: Date
    var weeklyProgresses: [WeeklyProgress]
    var totalCalories: Int
    var totalProtein: Double
    var totalFat: Double
    var totalCarbs: Double
    var averageCalories: Int
    var goalCompletionRate: Double
    var streak: Int
    
    var totalMeals: Int {
        return weeklyProgresses.reduce(0) { weekTotal, week in
            weekTotal + week.dailyProgresses.reduce(0) { dayTotal, day in
                dayTotal + day.mealsCount
            }
        }
    }
}

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let unlockedAt: Date
    let isUnlocked: Bool
    let points: Int
    
    enum AchievementCategory: String, Codable, CaseIterable {
        case goals = "Goals"
        case progress = "Progress"
        case streaks = "Streaks"
        case analysis = "Analysis"
        case social = "Social"
        case nutrition = "Nutrition"
        
        var color: String {
            switch self {
            case .goals: return "blue"
            case .progress: return "green"
            case .streaks: return "orange"
            case .analysis: return "purple"
            case .social: return "pink"
            case .nutrition: return "mint"
            }
        }
        
        var emoji: String {
            switch self {
            case .goals: return "🎯"
            case .progress: return "📈"
            case .streaks: return "🔥"
            case .analysis: return "🔬"
            case .social: return "👥"
            case .nutrition: return "🥗"
            }
        }
    }
}

// MARK: - User Profile Model
struct UserProfile: Codable {
    let age: Int
    let weight: Int // kg
    let height: Int // cm
    let gender: Gender
    let activityLevel: NutritionGoals.ActivityLevel
    let goal: NutritionGoals.Goal.GoalType
    let preferences: DietaryPreferences?
    let medicalConditions: [MedicalCondition]?
    let createdAt: Date
    let updatedAt: Date
    
    enum Gender: String, Codable {
        case male, female
        
        var displayName: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            }
        }
    }
    
    struct DietaryPreferences: Codable {
        let isVegetarian: Bool
        let isVegan: Bool
        let isGlutenFree: Bool
        let isDairyFree: Bool
        let allergies: [String]
        let dislikes: [String]
    }
    
    enum MedicalCondition: String, Codable, CaseIterable {
        case diabetes = "diabetes"
        case hypertension = "hypertension"
        case heartDisease = "heart_disease"
        case kidneyDisease = "kidney_disease"
        case thyroidDisorder = "thyroid_disorder"
        
        var displayName: String {
            switch self {
            case .diabetes: return "Diabetes"
            case .hypertension: return "Hypertension"
            case .heartDisease: return "Heart Disease"
            case .kidneyDisease: return "Kidney Disease"
            case .thyroidDisorder: return "Thyroid Disorder"
            }
        }
    }
    
    var bmi: Double {
        let heightInMeters = Double(height) / 100.0
        return Double(weight) / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
}

// MARK: - Goal Recommendations Model
struct GoalRecommendations: Codable {
    let dailyCalorieGoal: Int
    let proteinGoal: Double
    let fatGoal: Double
    let carbsGoal: Double
    let fiberGoal: Double
    let explanation: String
    let tips: [String]
    
    // Additional properties for RecommendationsView
    let bmr: Int
    let tdee: Int
    let goalType: NutritionGoals.Goal.GoalType
    
    // Computed properties for UI
    var calories: Int { dailyCalorieGoal }
    var protein: Double { proteinGoal }
    var carbs: Double { carbsGoal }
    var fat: Double { fatGoal }
    
    var macroCalorieBreakdown: (proteinCals: Int, fatCals: Int, carbsCals: Int) {
        return (
            proteinCals: Int(proteinGoal * 4),
            fatCals: Int(fatGoal * 9),
            carbsCals: Int(carbsGoal * 4)
        )
    }
    
    var macroPercentages: (protein: Double, fat: Double, carbs: Double) {
        let totalCals = Double(dailyCalorieGoal)
        guard totalCals > 0 else { return (0, 0, 0) }
        
        let proteinCals = proteinGoal * 4
        let fatCals = fatGoal * 9
        let carbsCals = carbsGoal * 4
        
        return (
            protein: (proteinCals / totalCals) * 100,
            fat: (fatCals / totalCals) * 100,
            carbs: (carbsCals / totalCals) * 100
        )
    }
}

// MARK: - String Extensions for Validation
extension String {
    var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        return count >= 8 &&
               contains(where: { $0.isLetter }) &&
               contains(where: { $0.isNumber })
    }
    
    var isValidName: Bool {
        return count >= 2 &&
               allSatisfy { $0.isLetter || $0.isWhitespace } &&
               trimmingCharacters(in: .whitespaces).count >= 2
    }
}

// MARK: - Date Extensions
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func formattedAs(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    var timeAgoDisplay: String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            let components = calendar.dateComponents([.hour, .minute], from: self, to: now)
            
            if let hours = components.hour, hours > 0 {
                return "\(hours)h ago"
            } else if let minutes = components.minute, minutes > 0 {
                return "\(minutes)m ago"
            } else {
                return "Just now"
            }
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let components = calendar.dateComponents([.day], from: self, to: now)
            if let days = components.day, days <= 7 {
                return "\(days)d ago"
            } else {
                return formattedAs("MMM d")
            }
        }
    }
}
