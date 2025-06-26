import Foundation
import Combine

// MARK: - Goals Repository Protocol
protocol GoalsRepositoryProtocol {
    func saveGoals(_ goals: NutritionGoals) -> AppResult<Void>
    func getCurrentGoals() -> AppResult<NutritionGoals?>
    func updateProgress(for date: Date, analysis: FoodAnalysisResponse) -> AppResult<Void>
    func getDailyProgress(for date: Date) -> AppResult<DailyProgress>
    func getWeeklyProgress() -> AppResult<WeeklyProgress>
    func getMonthlyProgress() -> AppResult<MonthlyProgress>
    func getAchievements() -> AppResult<[Achievement]>
    func generateGoalRecommendations(userProfile: UserProfile) -> AppResult<GoalRecommendations>
    
    // Reactive updates
    var goalsPublisher: AnyPublisher<NutritionGoals?, Never> { get }
    var progressPublisher: AnyPublisher<DailyProgress, Never> { get }
    var achievementsPublisher: AnyPublisher<[Achievement], Never> { get }
}

// MARK: - Goals Repository Implementation
final class GoalsRepository: GoalsRepositoryProtocol {
    private let userDefaults = UserDefaults.standard
    private let goalsKey = "nutrition_goals"
    private let progressKey = "daily_progress"
    private let achievementsKey = "achievements"
    
    private let goalsSubject = CurrentValueSubject<NutritionGoals?, Never>(nil)
    private let progressSubject = CurrentValueSubject<DailyProgress, Never>(DailyProgress.empty)
    private let achievementsSubject = CurrentValueSubject<[Achievement], Never>([])
    
    var goalsPublisher: AnyPublisher<NutritionGoals?, Never> {
        goalsSubject.eraseToAnyPublisher()
    }
    
    var progressPublisher: AnyPublisher<DailyProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }
    
    var achievementsPublisher: AnyPublisher<[Achievement], Never> {
        achievementsSubject.eraseToAnyPublisher()
    }
    
    init() {
        loadGoalsFromStorage()
        loadTodayProgress()
        loadAchievements()
    }
    
    // MARK: - Goals Management
    func saveGoals(_ goals: NutritionGoals) -> AppResult<Void> {
        do {
            let data = try JSONEncoder().encode(goals)
            userDefaults.set(data, forKey: goalsKey)
            goalsSubject.send(goals)
            
            // Check for new achievements
            checkGoalSettingAchievements()
            
            return .success(())
        } catch {
            return .failure(.storage(.encodingFailed))
        }
    }
    
    func getCurrentGoals() -> AppResult<NutritionGoals?> {
        return .success(goalsSubject.value)
    }
    
    // MARK: - Progress Tracking
    func updateProgress(for date: Date, analysis: FoodAnalysisResponse) -> AppResult<Void> {
        let dateKey = formatDateKey(date)
        var dailyProgress = loadDailyProgress(for: dateKey)
        
        // Add the analysis to today's progress
        dailyProgress.analyses.append(analysis)
        dailyProgress.totalCalories += analysis.calories
        dailyProgress.totalProtein += analysis.proteinValue
        dailyProgress.totalFat += analysis.fatValue
        dailyProgress.totalCarbs += analysis.carbsValue
        dailyProgress.lastUpdated = Date()
        
        // Calculate progress percentages if goals exist
        if let goals = goalsSubject.value {
            dailyProgress.calorieProgress = min(Double(dailyProgress.totalCalories) / Double(goals.dailyCalorieGoal), 1.0)
            dailyProgress.proteinProgress = min(dailyProgress.totalProtein / goals.proteinGoal, 1.0)
            dailyProgress.fatProgress = min(dailyProgress.totalFat / goals.fatGoal, 1.0)
            dailyProgress.carbsProgress = min(dailyProgress.totalCarbs / goals.carbsGoal, 1.0)
        }
        
        // Save progress
        let result = saveDailyProgress(dailyProgress, for: dateKey)
        
        // Update current progress if it's today
        if Calendar.current.isDateInToday(date) {
            progressSubject.send(dailyProgress)
        }
        
        // Check for achievements
        checkProgressAchievements(dailyProgress)
        
        return result
    }
    
    func getDailyProgress(for date: Date) -> AppResult<DailyProgress> {
        let dateKey = formatDateKey(date)
        let progress = loadDailyProgress(for: dateKey)
        return .success(progress)
    }
    
    func getWeeklyProgress() -> AppResult<WeeklyProgress> {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        var weeklyProgress = WeeklyProgress(
            weekStart: weekStart,
            dailyProgresses: [],
            totalCalories: 0,
            totalProtein: 0.0,
            totalFat: 0.0,
            totalCarbs: 0.0,
            averageCalories: 0,
            goalCompletionRate: 0.0
        )
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                let dateKey = formatDateKey(date)
                let dailyProgress = loadDailyProgress(for: dateKey)
                weeklyProgress.dailyProgresses.append(dailyProgress)
                weeklyProgress.totalCalories += dailyProgress.totalCalories
                weeklyProgress.totalProtein += dailyProgress.totalProtein
                weeklyProgress.totalFat += dailyProgress.totalFat
                weeklyProgress.totalCarbs += dailyProgress.totalCarbs
            }
        }
        
        weeklyProgress.averageCalories = weeklyProgress.totalCalories / 7
        
        // Calculate goal completion rate
        if let goals = goalsSubject.value {
            let calorieCompletion = Double(weeklyProgress.totalCalories) / (Double(goals.dailyCalorieGoal) * 7)
            let proteinCompletion = weeklyProgress.totalProtein / (goals.proteinGoal * 7)
            let fatCompletion = weeklyProgress.totalFat / (goals.fatGoal * 7)
            let carbsCompletion = weeklyProgress.totalCarbs / (goals.carbsGoal * 7)
            
            weeklyProgress.goalCompletionRate = (calorieCompletion + proteinCompletion + fatCompletion + carbsCompletion) / 4.0
        }
        
        return .success(weeklyProgress)
    }
    
    func getMonthlyProgress() -> AppResult<MonthlyProgress> {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        
        var monthlyProgress = MonthlyProgress(
            monthStart: monthStart,
            weeklyProgresses: [],
            totalCalories: 0,
            totalProtein: 0.0,
            totalFat: 0.0,
            totalCarbs: 0.0,
            averageCalories: 0,
            goalCompletionRate: 0.0,
            streak: 0
        )
        
        // Calculate weekly progresses for the month
        for weekOffset in 0..<5 { // Max 5 weeks in a month
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: monthStart),
               weekStart < now {
                switch getWeeklyProgress() {
                case .success(let weekly):
                    monthlyProgress.weeklyProgresses.append(weekly)
                    monthlyProgress.totalCalories += weekly.totalCalories
                    monthlyProgress.totalProtein += weekly.totalProtein
                    monthlyProgress.totalFat += weekly.totalFat
                    monthlyProgress.totalCarbs += weekly.totalCarbs
                case .failure:
                    break
                }
            }
        }
        
        monthlyProgress.averageCalories = daysInMonth > 0 ? monthlyProgress.totalCalories / daysInMonth : 0
        
        // Calculate streak
        monthlyProgress.streak = calculateCurrentStreak()
        
        return .success(monthlyProgress)
    }
    
    // MARK: - Achievements
    func getAchievements() -> AppResult<[Achievement]> {
        return .success(achievementsSubject.value)
    }
    
    // MARK: - Smart Recommendations
    func generateGoalRecommendations(userProfile: UserProfile) -> AppResult<GoalRecommendations> {
        let bmr = calculateBMR(userProfile)
        let tdee = bmr * userProfile.activityLevel.multiplier
        
        let calorieGoal: Int
        switch userProfile.goal {
        case .weightLoss:
            calorieGoal = Int(tdee * 0.85) // 15% deficit
        case .weightGain:
            calorieGoal = Int(tdee * 1.15) // 15% surplus
        case .maintenance:
            calorieGoal = Int(tdee)
        case .muscle:
            calorieGoal = Int(tdee * 1.1) // 10% surplus
        case .endurance:
            calorieGoal = Int(tdee * 1.05) // 5% surplus
        }
        
        // Macro recommendations based on goal
        let proteinGoal: Double
        let fatGoal: Double
        let carbsGoal: Double
        
        switch userProfile.goal {
        case .weightLoss:
            proteinGoal = Double(userProfile.weight) * 1.2 // Higher protein for muscle preservation
            fatGoal = Double(calorieGoal) * 0.25 / 9 // 25% of calories from fat
            carbsGoal = (Double(calorieGoal) - (proteinGoal * 4) - (fatGoal * 9)) / 4
        case .weightGain, .muscle:
            proteinGoal = Double(userProfile.weight) * 1.6 // Higher protein for muscle building
            fatGoal = Double(calorieGoal) * 0.30 / 9 // 30% of calories from fat
            carbsGoal = (Double(calorieGoal) - (proteinGoal * 4) - (fatGoal * 9)) / 4
        case .maintenance:
            proteinGoal = Double(userProfile.weight) * 1.0 // Moderate protein
            fatGoal = Double(calorieGoal) * 0.25 / 9 // 25% of calories from fat
            carbsGoal = (Double(calorieGoal) - (proteinGoal * 4) - (fatGoal * 9)) / 4
        case .endurance:
            proteinGoal = Double(userProfile.weight) * 1.0 // Moderate protein
            fatGoal = Double(calorieGoal) * 0.20 / 9 // 20% of calories from fat
            carbsGoal = (Double(calorieGoal) - (proteinGoal * 4) - (fatGoal * 9)) / 4 // Higher carbs for endurance
        }
        
        let recommendations = GoalRecommendations(
            dailyCalorieGoal: calorieGoal,
            proteinGoal: max(proteinGoal, 50), // Minimum 50g protein
            fatGoal: max(fatGoal, 30), // Minimum 30g fat
            carbsGoal: max(carbsGoal, 50), // Minimum 50g carbs
            fiberGoal: 25.0,
            explanation: generateExplanation(for: userProfile.goal, calories: calorieGoal),
            tips: generateTips(for: userProfile.goal)
        )
        
        return .success(recommendations)
    }
    
    // MARK: - Private Methods
    private func loadGoalsFromStorage() {
        guard let data = userDefaults.data(forKey: goalsKey),
              let goals = try? JSONDecoder().decode(NutritionGoals.self, from: data) else {
            return
        }
        goalsSubject.send(goals)
    }
    
    private func loadTodayProgress() {
        let today = formatDateKey(Date())
        let progress = loadDailyProgress(for: today)
        progressSubject.send(progress)
    }
    
    private func loadAchievements() {
        guard let data = userDefaults.data(forKey: achievementsKey),
              let achievements = try? JSONDecoder().decode([Achievement].self, from: data) else {
            achievementsSubject.send([])
            return
        }
        achievementsSubject.send(achievements)
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func loadDailyProgress(for dateKey: String) -> DailyProgress {
        let key = "\(progressKey)_\(dateKey)"
        guard let data = userDefaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(DailyProgress.self, from: data) else {
            return DailyProgress.empty
        }
        return progress
    }
    
    private func saveDailyProgress(_ progress: DailyProgress, for dateKey: String) -> AppResult<Void> {
        let key = "\(progressKey)_\(dateKey)"
        do {
            let data = try JSONEncoder().encode(progress)
            userDefaults.set(data, forKey: key)
            return .success(())
        } catch {
            return .failure(.storage(.encodingFailed))
        }
    }
    
    private func calculateBMR(_ profile: UserProfile) -> Double {
        // Mifflin-St Jeor Equation
        if profile.gender == .male {
            return 10 * Double(profile.weight) + 6.25 * Double(profile.height) - 5 * Double(profile.age) + 5
        } else {
            return 10 * Double(profile.weight) + 6.25 * Double(profile.height) - 5 * Double(profile.age) - 161
        }
    }
    
    private func generateExplanation(for goal: UserProfile.Goal, calories: Int) -> String {
        switch goal {
        case .weightLoss:
            return "This calorie target creates a sustainable deficit to help you lose weight while preserving muscle mass. Higher protein helps maintain metabolism."
        case .weightGain:
            return "This calorie surplus supports healthy weight gain. Focus on nutrient-dense foods and strength training for optimal results."
        case .maintenance:
            return "These targets help maintain your current weight while supporting your activity level and overall health."
        case .muscle:
            return "Higher calories and protein support muscle growth. Combine with resistance training for best results."
        case .endurance:
            return "Higher carbohydrates fuel your endurance activities while maintaining adequate protein for recovery."
        }
    }
    
    private func generateTips(for goal: UserProfile.Goal) -> [String] {
        switch goal {
        case .weightLoss:
            return [
                "Focus on lean proteins to maintain muscle",
                "Include plenty of vegetables for nutrients and satiety",
                "Stay hydrated - sometimes thirst feels like hunger",
                "Plan meals ahead to avoid impulsive choices"
            ]
        case .weightGain:
            return [
                "Eat frequent, nutrient-dense meals",
                "Include healthy fats like nuts and avocados",
                "Don't skip meals, even if you're not hungry",
                "Focus on liquid calories like smoothies"
            ]
        case .maintenance:
            return [
                "Listen to your hunger and fullness cues",
                "Maintain a balanced approach to eating",
                "Include a variety of foods for optimal nutrition",
                "Stay consistent with your eating patterns"
            ]
        case .muscle:
            return [
                "Eat protein within 2 hours of workouts",
                "Don't neglect carbs - they fuel your training",
                "Get adequate sleep for muscle recovery",
                "Be patient - muscle growth takes time"
            ]
        case .endurance:
            return [
                "Fuel before, during, and after long sessions",
                "Focus on complex carbohydrates",
                "Don't forget electrolyte replacement",
                "Time your nutrition around your training"
            ]
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        // Go backwards day by day until we find a day without progress
        while true {
            let dateKey = formatDateKey(currentDate)
            let progress = loadDailyProgress(for: dateKey)
            
            if progress.analyses.isEmpty {
                break
            }
            
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
            
            // Cap at 365 days to prevent infinite loop
            if streak >= 365 {
                break
            }
        }
        
        return streak
    }
    
    private func checkGoalSettingAchievements() {
        var achievements = achievementsSubject.value
        let firstGoalAchievement = Achievement(
            id: "first_goal_set",
            title: "Goal Setter",
            description: "Set your first nutrition goals",
            icon: "target",
            category: .goals,
            unlockedAt: Date(),
            isUnlocked: true
        )
        
        if !achievements.contains(where: { $0.id == firstGoalAchievement.id }) {
            achievements.append(firstGoalAchievement)
            saveAchievements(achievements)
        }
    }
    
    private func checkProgressAchievements(_ progress: DailyProgress) {
        var achievements = achievementsSubject.value
        
        // First analysis achievement
        if progress.analyses.count == 1 && !achievements.contains(where: { $0.id == "first_analysis" }) {
            let achievement = Achievement(
                id: "first_analysis",
                title: "First Step",
                description: "Complete your first food analysis",
                icon: "camera.fill",
                category: .progress,
                unlockedAt: Date(),
                isUnlocked: true
            )
            achievements.append(achievement)
        }
        
        // Daily goal achievement
        if progress.calorieProgress >= 0.9 && progress.calorieProgress <= 1.1 &&
           !achievements.contains(where: { $0.id == "daily_goal_met" }) {
            let achievement = Achievement(
                id: "daily_goal_met",
                title: "On Target",
                description: "Meet your daily calorie goal",
                icon: "checkmark.circle.fill",
                category: .progress,
                unlockedAt: Date(),
                isUnlocked: true
            )
            achievements.append(achievement)
        }
        
        // Streak achievements
        let streak = calculateCurrentStreak()
        if streak >= 7 && !achievements.contains(where: { $0.id == "week_streak" }) {
            let achievement = Achievement(
                id: "week_streak",
                title: "Week Warrior",
                description: "Track nutrition for 7 days in a row",
                icon: "flame.fill",
                category: .streaks,
                unlockedAt: Date(),
                isUnlocked: true
            )
            achievements.append(achievement)
        }
        
        saveAchievements(achievements)
    }
    
    private func saveAchievements(_ achievements: [Achievement]) {
        do {
            let data = try JSONEncoder().encode(achievements)
            userDefaults.set(data, forKey: achievementsKey)
            achievementsSubject.send(achievements)
        } catch {
            // Handle encoding error
        }
    }
}

// MARK: - Supporting Types
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
}

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let unlockedAt: Date
    let isUnlocked: Bool
    
    enum AchievementCategory: String, Codable, CaseIterable {
        case goals = "Goals"
        case progress = "Progress"
        case streaks = "Streaks"
        case analysis = "Analysis"
        case social = "Social"
    }
}

struct UserProfile: Codable {
    let age: Int
    let weight: Int // kg
    let height: Int // cm
    let gender: Gender
    let activityLevel: ActivityLevel
    let goal: Goal
    
    enum Gender: String, Codable {
        case male, female
    }
    
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
    }
    
    enum Goal: String, Codable, CaseIterable {
        case weightLoss = "weight_loss"
        case weightGain = "weight_gain"
        case maintenance = "maintenance"
        case muscle = "muscle_gain"
        case endurance = "endurance"
    }
}

struct GoalRecommendations: Codable {
    let dailyCalorieGoal: Int
    let proteinGoal: Double
    let fatGoal: Double
    let carbsGoal: Double
    let fiberGoal: Double
    let explanation: String
    let tips: [String]
}