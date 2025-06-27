import Foundation
import UIKit

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
    
    // Computed properties for backward compatibility
    var proteinValue: Double {
        return Double(protein.replacingOccurrences(of: "g", with: "")) ?? 0.0
    }
    
    var fatValue: Double {
        return Double(fat.replacingOccurrences(of: "g", with: "")) ?? 0.0
    }
    
    var carbsValue: Double {
        return Double(carbs.replacingOccurrences(of: "g", with: "")) ?? 0.0
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
    
    // Default values for enhanced features (can be added later)
    var fiber: Double? { nil }
    var sugar: Double? { nil }
    var sodium: Double? { nil }
    var confidence: Double { 0.9 }
    var imageURL: String? { nil }
    var nutritionGrade: NutritionGrade { .good }
    var macroBreakdown: MacroBreakdown { 
        MacroBreakdown(
            proteinPercentage: proteinValue,
            fatPercentage: fatValue,
            carbsPercentage: carbsValue
        )
    }
    var insights: [NutritionInsight] { [] }
    
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
    }
    
    // Calculate total calories from macros
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
    }
    
    struct Goal: Codable, Identifiable {
        let id = UUID()
        let type: GoalType
        let target: Double
        let current: Double
        let deadline: Date?
        
        enum GoalType: String, Codable {
            case weightLoss = "weight_loss"
            case weightGain = "weight_gain"
            case maintenance = "maintenance"
            case muscle = "muscle_gain"
            case endurance = "endurance"
        }
        
        var progress: Double {
            guard target > 0 else { return 0 }
            return min(current / target, 1.0)
        }
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
}
