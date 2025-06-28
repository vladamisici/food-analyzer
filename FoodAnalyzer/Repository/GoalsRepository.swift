import Foundation
import Combine

// MARK: - Goals Repository Protocol
protocol GoalsRepositoryProtocol {
    func saveGoals(_ goals: NutritionGoals) -> AppResult<Void>
    func getCurrentGoals() -> AppResult<NutritionGoals?>
    func updateProgress(for date: Date, analysis: FoodAnalysisResponse) -> AppResult<Void>
    func getDailyProgress(for date: Date) -> AppResult<DailyProgress>
    func getWeeklyProgress(for date: Date) -> AppResult<WeeklyProgress>
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
            var updatedGoals = goals
            updatedGoals.updatedAt = Date()
            
            let data = try JSONEncoder().encode(updatedGoals)
            userDefaults.set(data, forKey: goalsKey)
            goalsSubject.send(updatedGoals)
            
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
    
    func getWeeklyProgress(for date: Date) -> AppResult<WeeklyProgress> {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        
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
            if let currentDate = calendar.date(byAdding: .day, value: i, to: weekStart) {
                let dateKey = formatDateKey(currentDate)
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
                // Use the corrected method signature
                switch getWeeklyProgress(for: weekStart) {
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
            tips: generateTips(for: userProfile.goal),
            bmr: Int(bmr),
            tdee: Int(tdee),
            goalType: userProfile.goal
        )
        
        return .success(recommendations)
    }
    
    // MARK: - Enhanced Achievement System
    func unlockAchievement(_ achievementId: String) -> AppResult<Achievement?> {
        guard let achievement = createAchievement(with: achievementId) else {
            return .success(nil)
        }
        
        var achievements = achievementsSubject.value
        if !achievements.contains(where: { $0.id == achievementId }) {
            achievements.append(achievement)
            saveAchievements(achievements)
            return .success(achievement)
        }
        
        return .success(nil)
    }
    
    func getAchievementProgress() -> AppResult<AchievementProgress> {
        let achievements = achievementsSubject.value
        let totalPoints = achievements.reduce(0) { $0 + $1.points }
        let unlockedCount = achievements.filter { $0.isUnlocked }.count
        
        let progress = AchievementProgress(
            totalAchievements: achievements.count,
            unlockedAchievements: unlockedCount,
            totalPoints: totalPoints,
            currentStreak: calculateCurrentStreak(),
            level: calculateUserLevel(points: totalPoints)
        )
        
        return .success(progress)
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
        let baseValue = 10 * Double(profile.weight) + 6.25 * Double(profile.height) - 5 * Double(profile.age)
        
        switch profile.gender {
        case .male:
            return baseValue + 5
        case .female:
            return baseValue - 161
        }
    }
    
    private func generateExplanation(for goal: NutritionGoals.Goal.GoalType, calories: Int) -> String {
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
    
    private func generateTips(for goal: NutritionGoals.Goal.GoalType) -> [String] {
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
    
    private func calculateUserLevel(points: Int) -> Int {
        // Level system: 100 points per level
        return max(1, points / 100 + 1)
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
            isUnlocked: true,
            points: 50
        )
        
        if !achievements.contains(where: { $0.id == firstGoalAchievement.id }) {
            achievements.append(firstGoalAchievement)
            saveAchievements(achievements)
        }
    }
    
    private func checkProgressAchievements(_ progress: DailyProgress) {
        var achievements = achievementsSubject.value
        var newAchievements: [Achievement] = []
        
        // First analysis achievement
        if progress.analyses.count == 1 && !achievements.contains(where: { $0.id == "first_analysis" }) {
            let achievement = Achievement(
                id: "first_analysis",
                title: "First Step",
                description: "Complete your first food analysis",
                icon: "camera.fill",
                category: .progress,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 25
            )
            newAchievements.append(achievement)
        }
        
        // Daily goal achievement
        if progress.isGoalMet && !achievements.contains(where: { $0.id == "daily_goal_met" }) {
            let achievement = Achievement(
                id: "daily_goal_met",
                title: "On Target",
                description: "Meet your daily nutrition goals",
                icon: "checkmark.circle.fill",
                category: .progress,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 100
            )
            newAchievements.append(achievement)
        }
        
        // Multiple meals in a day
        if progress.analyses.count >= 3 && !achievements.contains(where: { $0.id == "three_meals_day" }) {
            let achievement = Achievement(
                id: "three_meals_day",
                title: "Full Day",
                description: "Track 3 or more meals in a single day",
                icon: "fork.knife",
                category: .analysis,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 75
            )
            newAchievements.append(achievement)
        }
        
        // Streak achievements
        let streak = calculateCurrentStreak()
        
        if streak >= 3 && !achievements.contains(where: { $0.id == "three_day_streak" }) {
            newAchievements.append(Achievement(
                id: "three_day_streak",
                title: "Getting Started",
                description: "Track nutrition for 3 days in a row",
                icon: "flame.fill",
                category: .streaks,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 150
            ))
        }
        
        if streak >= 7 && !achievements.contains(where: { $0.id == "week_streak" }) {
            newAchievements.append(Achievement(
                id: "week_streak",
                title: "Week Warrior",
                description: "Track nutrition for 7 days in a row",
                icon: "flame.fill",
                category: .streaks,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 300
            ))
        }
        
        if streak >= 30 && !achievements.contains(where: { $0.id == "month_streak" }) {
            newAchievements.append(Achievement(
                id: "month_streak",
                title: "Monthly Master",
                description: "Track nutrition for 30 days in a row",
                icon: "flame.fill",
                category: .streaks,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 1000
            ))
        }
        
        // High protein meal achievement
        if let lastAnalysis = progress.analyses.last,
           lastAnalysis.isHighProtein && !achievements.contains(where: { $0.id == "high_protein_meal" }) {
            newAchievements.append(Achievement(
                id: "high_protein_meal",
                title: "Protein Power",
                description: "Analyze a meal with 20g+ protein",
                icon: "bolt.fill",
                category: .nutrition,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 50
            ))
        }
        
        // Balanced meal achievement
        if let lastAnalysis = progress.analyses.last,
           lastAnalysis.isBalanced && !achievements.contains(where: { $0.id == "balanced_meal" }) {
            newAchievements.append(Achievement(
                id: "balanced_meal",
                title: "Perfect Balance",
                description: "Analyze a well-balanced meal",
                icon: "scale.3d",
                category: .nutrition,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 75
            ))
        }
        
        // Add new achievements and save
        if !newAchievements.isEmpty {
            achievements.append(contentsOf: newAchievements)
            saveAchievements(achievements)
        }
    }
    
    private func createAchievement(with id: String) -> Achievement? {
        // Factory method for creating achievements
        switch id {
        case "nutritionist":
            return Achievement(
                id: "nutritionist",
                title: "Nutritionist",
                description: "Analyze 100 meals",
                icon: "graduationcap.fill",
                category: .analysis,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 500
            )
        case "health_guru":
            return Achievement(
                id: "health_guru",
                title: "Health Guru",
                description: "Maintain a 30-day streak with excellent nutrition",
                icon: "crown.fill",
                category: .streaks,
                unlockedAt: Date(),
                isUnlocked: true,
                points: 2000
            )
        default:
            return nil
        }
    }
    
    private func saveAchievements(_ achievements: [Achievement]) {
        do {
            let data = try JSONEncoder().encode(achievements)
            userDefaults.set(data, forKey: achievementsKey)
            achievementsSubject.send(achievements)
        } catch {
            // Handle encoding error silently for now
            print("Failed to save achievements: \(error)")
        }
    }
}

// MARK: - Supporting Types
struct AchievementProgress: Codable {
    let totalAchievements: Int
    let unlockedAchievements: Int
    let totalPoints: Int
    let currentStreak: Int
    let level: Int
    
    var completionPercentage: Double {
        guard totalAchievements > 0 else { return 0 }
        return Double(unlockedAchievements) / Double(totalAchievements) * 100
    }
    
    var pointsToNextLevel: Int {
        let currentLevelPoints = (level - 1) * 100
        let nextLevelPoints = level * 100
        return nextLevelPoints - totalPoints
    }
}
