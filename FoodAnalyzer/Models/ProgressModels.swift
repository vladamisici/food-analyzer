import Foundation

// MARK: - Progress Models
struct DailyProgress: Codable, Equatable {
    let date: Date
    var consumedCalories: Int
    var consumedProtein: Double
    var consumedCarbs: Double
    var consumedFat: Double
    var consumedFiber: Double
    var meals: [FoodAnalysisResponse]
    
    static let empty = DailyProgress(
        date: Date(),
        consumedCalories: 0,
        consumedProtein: 0,
        consumedCarbs: 0,
        consumedFat: 0,
        consumedFiber: 0,
        meals: []
    )
}

struct WeeklyProgress: Codable {
    let days: [DailyProgress]
    let totalCalories: Int
    let averageCalories: Double
}

struct MonthlyProgress: Codable {
    let weeks: [WeeklyProgress]
    let totalCalories: Int
    let averageCalories: Double
}

// MARK: - Achievement Models
struct Achievement: Codable, Identifiable {
    let id = UUID()
    let type: AchievementType
    let title: String
    let description: String
    let iconName: String
    let unlockedAt: Date
    let progress: Double
    
    enum AchievementType: String, Codable {
        case streak
        case calorieGoal
        case proteinGoal
        case healthyChoices
        case totalAnalyses
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    let age: Int
    let weight: Int // in kg
    let height: Int // in cm
    let gender: Gender
    let activityLevel: NutritionGoals.ActivityLevel
    let goal: NutritionGoals.Goal.GoalType
    
    enum Gender: String, Codable {
        case male
        case female
        case other
    }
}

// MARK: - Goal Recommendations
struct GoalRecommendations: Codable {
    let dailyCalorieGoal: Int
    let proteinGoal: Double
    let fatGoal: Double
    let carbGoal: Double
    let fiberGoal: Double?
    let explanation: String?
    let tips: [String]?
    let bmr: Int?
    let tdee: Int?
    let goalType: NutritionGoals.Goal.GoalType?
    
    init(calorieGoal: Int, proteinGoal: Double, carbGoal: Double, fatGoal: Double, reasoning: String) {
        self.dailyCalorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.fatGoal = fatGoal
        self.carbGoal = carbGoal
        self.fiberGoal = 25.0
        self.explanation = reasoning
        self.tips = []
        self.bmr = nil
        self.tdee = nil
        self.goalType = nil
    }
}