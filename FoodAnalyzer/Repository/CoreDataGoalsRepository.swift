import Foundation
import CoreData
import Combine

class CoreDataGoalsRepository: GoalsRepositoryProtocol {
    private let coreDataManager = CoreDataManager.shared
    private let currentUserSubject = CurrentValueSubject<User?, Never>(nil)
    
    private let goalsSubject = CurrentValueSubject<NutritionGoals?, Never>(nil)
    private let progressSubject = CurrentValueSubject<DailyProgress, Never>(DailyProgress.empty)
    private let achievementsSubject = CurrentValueSubject<[Achievement], Never>([])
    
    var currentUser: User? {
        get { currentUserSubject.value }
        set { currentUserSubject.send(newValue) }
    }
    
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
    }
    
    // MARK: - Protocol Implementation
    func saveGoals(_ goals: NutritionGoals) -> AppResult<Void> {
        guard let userId = currentUser?.id else {
            return .failure(.authentication(.unauthorized))
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: AppResult<Void> = .success(())
        
        Task {
            do {
                try await coreDataManager.performBackgroundTask { context in
                    let request = NutritionGoalEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@", userId)
                    
                    if let existingEntity = try context.fetch(request).first {
                        existingEntity.update(from: goals)
                    } else {
                        _ = NutritionGoalEntity.from(goals, userId: userId, in: context)
                    }
                    
                    try context.save()
                }
                
                goalsSubject.send(goals)
                result = .success(())
            } catch let error as AppError {
                result = .failure(error)
            } catch {
                result = .failure(.unknown(error.localizedDescription))
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func getCurrentGoals() -> AppResult<NutritionGoals?> {
        guard let userId = currentUser?.id else {
            return .failure(.authentication(.unauthorized))
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: AppResult<NutritionGoals?> = .success(nil)
        
        Task {
            do {
                let goals = try await coreDataManager.performBackgroundTask { context -> NutritionGoals? in
                    let request = NutritionGoalEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "userId == %@", userId)
                    
                    if let entity = try context.fetch(request).first {
                        return entity.toNutritionGoals()
                    }
                    
                    return nil  // Now this is valid since we explicitly specify NutritionGoals? as return type
                }
                
                result = .success(goals)
            } catch let error as AppError {
                result = .failure(error)
            } catch {
                result = .failure(.unknown(error.localizedDescription))
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func updateProgress(for date: Date, analysis: FoodAnalysisResponse) -> AppResult<Void> {
        // TODO: Implement actual progress tracking with Core Data
        // For now, just return success
        return .success(())
    }
    
    func getDailyProgress(for date: Date) -> AppResult<DailyProgress> {
        // TODO: Implement actual daily progress loading from Core Data
        return .success(DailyProgress.empty)
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
        
        // Load daily progress for each day of the week
        for dayOffset in 0..<7 {
            if let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                switch getDailyProgress(for: currentDate) {
                case .success(let dailyProgress):
                    weeklyProgress.dailyProgresses.append(dailyProgress)
                    weeklyProgress.totalCalories += dailyProgress.totalCalories
                    weeklyProgress.totalProtein += dailyProgress.totalProtein
                    weeklyProgress.totalFat += dailyProgress.totalFat
                    weeklyProgress.totalCarbs += dailyProgress.totalCarbs
                case .failure:
                    // Add empty progress for days with no data
                    weeklyProgress.dailyProgresses.append(DailyProgress.empty)
                }
            }
        }
        
        // Calculate averages
        weeklyProgress.averageCalories = weeklyProgress.totalCalories / 7
        
        // Calculate goal completion rate if goals exist
        switch getCurrentGoals() {
        case .success(let optionalGoals):
            if let goals = optionalGoals {
                let calorieCompletion = Double(weeklyProgress.totalCalories) / (Double(goals.dailyCalorieGoal) * 7)
                let proteinCompletion = weeklyProgress.totalProtein / (goals.proteinGoal * 7)
                let fatCompletion = weeklyProgress.totalFat / (goals.fatGoal * 7)
                let carbsCompletion = weeklyProgress.totalCarbs / (goals.carbsGoal * 7)
                
                weeklyProgress.goalCompletionRate = (calorieCompletion + proteinCompletion + fatCompletion + carbsCompletion) / 4.0
            }
        case .failure:
            break
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
        
        // Calculate averages
        monthlyProgress.averageCalories = daysInMonth > 0 ? monthlyProgress.totalCalories / daysInMonth : 0
        
        // Calculate goal completion rate
        switch getCurrentGoals() {
        case .success(let optionalGoals):
            if let goals = optionalGoals {
                let totalDays = Double(daysInMonth)
                let calorieCompletion = Double(monthlyProgress.totalCalories) / (Double(goals.dailyCalorieGoal) * totalDays)
                let proteinCompletion = monthlyProgress.totalProtein / (goals.proteinGoal * totalDays)
                let fatCompletion = monthlyProgress.totalFat / (goals.fatGoal * totalDays)
                let carbsCompletion = monthlyProgress.totalCarbs / (goals.carbsGoal * totalDays)
                
                monthlyProgress.goalCompletionRate = (calorieCompletion + proteinCompletion + fatCompletion + carbsCompletion) / 4.0
            }
        case .failure:
            break
        }
        
        // Calculate streak
        monthlyProgress.streak = calculateCurrentStreak()
        
        return .success(monthlyProgress)
    }
    
    func getAchievements() -> AppResult<[Achievement]> {
        // TODO: Implement actual achievements loading from Core Data
        return .success([])
    }
    
    func generateGoalRecommendations(userProfile: UserProfile) -> AppResult<GoalRecommendations> {
        // Calculate BMR using Mifflin-St Jeor Equation
        let bmr = calculateBMR(userProfile)
        
        // Calculate TDEE (Total Daily Energy Expenditure)
        let tdee = bmr * userProfile.activityLevel.multiplier
        
        // Determine calorie goal based on user's goal
        let calorieGoal: Int
        switch userProfile.goal {
        case .weightLoss:
            calorieGoal = Int(tdee * 0.85) // 15% deficit
        case .weightGain:
            calorieGoal = Int(tdee * 1.15) // 15% surplus
        case .maintenance:
            calorieGoal = Int(tdee)
        case .muscle:
            calorieGoal = Int(tdee * 1.1) // 10% surplus for muscle building
        case .endurance:
            calorieGoal = Int(tdee * 1.05) // 5% surplus for endurance training
        }
        
        // Calculate macro goals based on user's goal
        let (proteinGoal, fatGoal, carbsGoal) = calculateMacroGoals(
            calorieGoal: calorieGoal,
            userWeight: userProfile.weight,
            goal: userProfile.goal
        )
        
        // Standard fiber goal
        let fiberGoal: Double = 25.0
        
        // Generate explanation
        let explanation = generateExplanation(for: userProfile.goal, calories: calorieGoal)
        
        // Generate tips
        let tips = generateTips(for: userProfile.goal)
        
        let recommendations = GoalRecommendations(
            dailyCalorieGoal: calorieGoal,
            proteinGoal: proteinGoal,
            fatGoal: fatGoal,
            carbsGoal: carbsGoal,
            fiberGoal: fiberGoal,
            explanation: explanation,
            tips: tips,
            bmr: Int(bmr),
            tdee: Int(tdee),
            goalType: userProfile.goal
        )
        
        return .success(recommendations)
    }
    
    // MARK: - Private Helper Methods
    private func loadGoalsFromStorage() {
        // Load goals on initialization
        switch getCurrentGoals() {
        case .success(let goals):
            goalsSubject.send(goals)
        case .failure:
            goalsSubject.send(nil)
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        // Go backwards day by day until we find a day without progress
        while true {
            switch getDailyProgress(for: currentDate) {
            case .success(let progress):
                // Check if user tracked anything on this day
                if progress.analyses.isEmpty {
                    // No tracking on this day - streak ends here
                    break
                }
                
                // Day has tracking - increment streak
                streak += 1
                
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
                
                // Cap at 365 days to prevent infinite loop and performance issues
                if streak >= 365 {
                    break
                }
                
            case .failure:
                // Failed to load progress - assume no tracking
                break
            }
        }
        
        return streak
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
    
    private func calculateMacroGoals(calorieGoal: Int, userWeight: Int, goal: NutritionGoals.Goal.GoalType) -> (protein: Double, fat: Double, carbs: Double) {
        
        let proteinGoal: Double
        let fatGoal: Double
        let carbsGoal: Double
        
        switch goal {
        case .weightLoss:
            // Higher protein for muscle preservation during weight loss
            proteinGoal = Double(userWeight) * 1.2 // 1.2g per kg body weight
            fatGoal = Double(calorieGoal) * 0.25 / 9 // 25% of calories from fat
            carbsGoal = (Double(calorieGoal) - (proteinGoal * 4) - (fatGoal * 9)) / 4 // Remaining calories from carbs
            
        case .weightGain, .muscle:
            // Higher protein for muscle building
            proteinGoal = Double(userWeight) * 1.6 // 1.6g per kg body weight
            fatGoal = Double(calorieGoal) * 0.30 / 9 // 30% of calories from fat
            carbsGoal = (Double(calorieGoal) - (proteinGoal * 4) - (fatGoal * 9)) / 4
            
        case .maintenance:
            // Moderate protein for maintenance
            proteinGoal = Double(userWeight) * 1.0 // 1.0g per kg body weight
            fatGoal = Double(calorieGoal) * 0.25 / 9 // 25% of calories from fat
            carbsGoal = (Double(calorieGoal) - (proteinGoal * 4) - (fatGoal * 9)) / 4
            
        case .endurance:
            // Higher carbs for endurance training
            proteinGoal = Double(userWeight) * 1.0 // 1.0g per kg body weight
            fatGoal = Double(calorieGoal) * 0.20 / 9 // 20% of calories from fat
            carbsGoal = (Double(calorieGoal) - (proteinGoal * 4) - (fatGoal * 9)) / 4 // Higher carbs
        }
        
        // Ensure minimum values
        let finalProtein = max(proteinGoal, 50.0) // Minimum 50g protein
        let finalFat = max(fatGoal, 30.0) // Minimum 30g fat
        let finalCarbs = max(carbsGoal, 50.0) // Minimum 50g carbs
        
        return (protein: finalProtein, fat: finalFat, carbs: finalCarbs)
    }
    
    private func generateExplanation(for goal: NutritionGoals.Goal.GoalType, calories: Int) -> String {
        switch goal {
        case .weightLoss:
            return "This calorie target creates a sustainable deficit to help you lose weight while preserving muscle mass. Higher protein helps maintain metabolism and keeps you feeling full."
        case .weightGain:
            return "This calorie surplus supports healthy weight gain. Focus on nutrient-dense foods and combine with strength training for optimal results."
        case .maintenance:
            return "These targets help maintain your current weight while supporting your activity level and overall health. Perfect for long-term sustainable nutrition."
        case .muscle:
            return "Higher calories and protein support muscle growth. The increased protein intake aids in muscle protein synthesis when combined with resistance training."
        case .endurance:
            return "Higher carbohydrates fuel your endurance activities while maintaining adequate protein for recovery. This ratio optimizes performance and recovery."
        }
    }
    
    private func generateTips(for goal: NutritionGoals.Goal.GoalType) -> [String] {
        switch goal {
        case .weightLoss:
            return [
                "Focus on lean proteins like chicken, fish, and legumes",
                "Include plenty of vegetables for nutrients and satiety",
                "Stay hydrated - sometimes thirst feels like hunger",
                "Plan meals ahead to avoid impulsive food choices"
            ]
        case .weightGain:
            return [
                "Eat frequent, nutrient-dense meals throughout the day",
                "Include healthy fats like nuts, avocados, and olive oil",
                "Don't skip meals, even if you're not feeling hungry",
                "Consider liquid calories like smoothies and protein shakes"
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
                "Eat protein within 2 hours of strength training workouts",
                "Don't neglect carbs - they fuel your training sessions",
                "Get adequate sleep for muscle recovery and growth",
                "Be patient - muscle growth takes time and consistency"
            ]
        case .endurance:
            return [
                "Fuel before, during, and after long training sessions",
                "Focus on complex carbohydrates for sustained energy",
                "Don't forget electrolyte replacement during long activities",
                "Time your nutrition around your training schedule"
            ]
        }
    }
}
