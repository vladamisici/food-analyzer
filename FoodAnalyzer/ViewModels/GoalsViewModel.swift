import Foundation
import SwiftUI
import Combine

@MainActor
final class GoalsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentGoals: NutritionGoals?
    @Published var dailyProgress: DailyProgress = .empty
    @Published var weeklyProgress: WeeklyProgress?
    @Published var monthlyProgress: MonthlyProgress?
    @Published var achievements: [Achievement] = []
    @Published var goalRecommendations: GoalRecommendations?
    
    // Goal Setting
    @Published var isEditingGoals = false
    @Published var editingGoals = EditableGoals()
    @Published var tempCalorieGoal: String = ""
    @Published var tempProteinGoal: String = ""
    @Published var tempFatGoal: String = ""
    @Published var tempCarbsGoal: String = ""
    @Published var tempFiberGoal: String = ""
    @Published var selectedActivityLevel: NutritionGoals.ActivityLevel = .moderately
    
    // User Profile for Recommendations
    @Published var showProfileSetup = false
    @Published var userAge: String = ""
    @Published var userWeight: String = ""
    @Published var userHeight: String = ""
    @Published var userGender: UserProfile.Gender = .male
    @Published var userActivityLevel: UserProfile.ActivityLevel = .moderately
    @Published var userGoal: UserProfile.Goal = .maintenance
    
    // UI State
    @Published var isLoading = false
    @Published var showAchievements = false
    @Published var showProgressDetail = false
    @Published var selectedProgressPeriod: ProgressPeriod = .daily
    @Published var showGoalRecommendations = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccessMessage = false
    @Published var successMessage: String?
    
    // MARK: - Dependencies
    private let goalsRepository: GoalsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var hasGoals: Bool {
        currentGoals != nil
    }
    
    var todayGoalCompletion: Double {
        guard hasGoals else { return 0 }
        return (dailyProgress.calorieProgress + dailyProgress.proteinProgress + 
                dailyProgress.fatProgress + dailyProgress.carbsProgress) / 4.0
    }
    
    var isOnTrack: Bool {
        todayGoalCompletion >= 0.8 && todayGoalCompletion <= 1.2
    }
    
    var streakDays: Int {
        monthlyProgress?.streak ?? 0
    }
    
    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }
    
    var availableAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }
    
    var motivationalMessage: String {
        if !hasGoals {
            return "Set your nutrition goals to start tracking your progress! 🎯"
        }
        
        let completion = todayGoalCompletion
        if completion < 0.3 {
            return "Start strong today! Every healthy choice counts 💪"
        } else if completion < 0.7 {
            return "You're making progress! Keep going 🚀"
        } else if completion >= 0.9 && completion <= 1.1 {
            return "Perfect! You're hitting your goals 🎉"
        } else if completion > 1.3 {
            return "You've exceeded your goals! Consider adjusting them 📈"
        } else {
            return "Almost there! You've got this 🔥"
        }
    }
    
    // MARK: - Initialization
    init(goalsRepository: GoalsRepositoryProtocol = GoalsRepository()) {
        self.goalsRepository = goalsRepository
        setupBindings()
        loadGoals()
        loadProgress()
        loadAchievements()
    }
    
    // MARK: - Public Methods
    func loadGoals() {
        switch goalsRepository.getCurrentGoals() {
        case .success(let goals):
            currentGoals = goals
            if let goals = goals {
                updateTempGoals(from: goals)
            }
        case .failure(let error):
            showError(error)
        }
    }
    
    func saveGoals() {
        guard let calorieGoal = Int(tempCalorieGoal),
              let proteinGoal = Double(tempProteinGoal),
              let fatGoal = Double(tempFatGoal),
              let carbsGoal = Double(tempCarbsGoal),
              let fiberGoal = Double(tempFiberGoal) else {
            showError(.validation(.emptyFields))
            return
        }
        
        let goals = NutritionGoals(
            dailyCalorieGoal: calorieGoal,
            proteinGoal: proteinGoal,
            fatGoal: fatGoal,
            carbsGoal: carbsGoal,
            fiberGoal: fiberGoal,
            activityLevel: selectedActivityLevel,
            goals: currentGoals?.goals ?? []
        )
        
        switch goalsRepository.saveGoals(goals) {
        case .success:
            currentGoals = goals
            isEditingGoals = false
            showSuccessMessage("Goals updated successfully! 🎯")
            loadProgress() // Refresh progress calculations
        case .failure(let error):
            showError(error)
        }
    }
    
    func generateRecommendations() {
        guard let age = Int(userAge),
              let weight = Int(userWeight),
              let height = Int(userHeight) else {
            showError(.validation(.emptyFields))
            return
        }
        
        let profile = UserProfile(
            age: age,
            weight: weight,
            height: height,
            gender: userGender,
            activityLevel: userActivityLevel,
            goal: userGoal
        )
        
        switch goalsRepository.generateGoalRecommendations(userProfile: profile) {
        case .success(let recommendations):
            goalRecommendations = recommendations
            
            // Pre-fill the temp goals with recommendations
            tempCalorieGoal = String(recommendations.dailyCalorieGoal)
            tempProteinGoal = String(Int(recommendations.proteinGoal))
            tempFatGoal = String(Int(recommendations.fatGoal))
            tempCarbsGoal = String(Int(recommendations.carbsGoal))
            tempFiberGoal = String(Int(recommendations.fiberGoal))
            
            showGoalRecommendations = true
        case .failure(let error):
            showError(error)
        }
    }
    
    func applyRecommendations() {
        guard let recommendations = goalRecommendations else { return }
        
        tempCalorieGoal = String(recommendations.dailyCalorieGoal)
        tempProteinGoal = String(Int(recommendations.proteinGoal))
        tempFatGoal = String(Int(recommendations.fatGoal))
        tempCarbsGoal = String(Int(recommendations.carbsGoal))
        tempFiberGoal = String(Int(recommendations.fiberGoal))
        
        showGoalRecommendations = false
        showSuccessMessage("Recommendations applied! 📊")
    }
    
    func generateGoalRecommendations(profile: UserProfile) {
        switch goalsRepository.generateGoalRecommendations(userProfile: profile) {
        case .success(let recommendations):
            goalRecommendations = recommendations
            
            // Pre-fill the temp goals with recommendations
            tempCalorieGoal = String(recommendations.dailyCalorieGoal)
            tempProteinGoal = String(Int(recommendations.proteinGoal))
            tempFatGoal = String(Int(recommendations.fatGoal))
            tempCarbsGoal = String(Int(recommendations.carbsGoal))
            tempFiberGoal = String(Int(recommendations.fiberGoal))
            
            showGoalRecommendations = true
            showSuccessMessage("Recommendations generated! 🎯")
        case .failure(let error):
            showError(error)
        }
    }
    
    func customizeRecommendations() {
        guard let recommendations = goalRecommendations else { return }
        
        // Pre-fill temp goals with current recommendations
        tempCalorieGoal = String(recommendations.dailyCalorieGoal)
        tempProteinGoal = String(Int(recommendations.proteinGoal))
        tempFatGoal = String(Int(recommendations.fatGoal))
        tempCarbsGoal = String(Int(recommendations.carbsGoal))
        tempFiberGoal = String(Int(recommendations.fiberGoal))
        
        showGoalRecommendations = false
        isEditingGoals = true
    }
    
    func updateProgress(with analysis: FoodAnalysisResponse) {
        switch goalsRepository.updateProgress(for: Date(), analysis: analysis) {
        case .success:
            loadProgress()
            loadAchievements() // Check for new achievements
        case .failure(let error):
            showError(error)
        }
    }
    
    func loadProgress() {
        // Load daily progress
        switch goalsRepository.getDailyProgress(for: Date()) {
        case .success(let progress):
            dailyProgress = progress
        case .failure(let error):
            showError(error)
        }
        
        // Load weekly progress
        switch goalsRepository.getWeeklyProgress() {
        case .success(let progress):
            weeklyProgress = progress
        case .failure(let error):
            showError(error)
        }
        
        // Load monthly progress
        switch goalsRepository.getMonthlyProgress() {
        case .success(let progress):
            monthlyProgress = progress
        case .failure(let error):
            showError(error)
        }
    }
    
    func loadAchievements() {
        switch goalsRepository.getAchievements() {
        case .success(let loadedAchievements):
            achievements = loadedAchievements
        case .failure(let error):
            showError(error)
        }
    }
    
    func cancelEditingGoals() {
        isEditingGoals = false
        if let goals = currentGoals {
            updateTempGoals(from: goals)
        }
    }
    
    func resetGoals() {
        tempCalorieGoal = ""
        tempProteinGoal = ""
        tempFatGoal = ""
        tempCarbsGoal = ""
        tempFiberGoal = ""
        currentGoals = nil
        isEditingGoals = false
    }
    
    func shareProgress() {
        let progressText = generateProgressShareText()
        
        let activityVC = UIActivityViewController(
            activityItems: [progressText],
            applicationActivities: nil
        )
        
        // Present activity controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Listen to repository updates
        goalsRepository.goalsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goals in
                self?.currentGoals = goals
            }
            .store(in: &cancellables)
        
        goalsRepository.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.dailyProgress = progress
            }
            .store(in: &cancellables)
        
        goalsRepository.achievementsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] achievements in
                self?.achievements = achievements
            }
            .store(in: &cancellables)
        
        // Auto-hide success messages
        $showSuccessMessage
            .filter { $0 }
            .delay(for: .seconds(3), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.hideSuccessMessage()
            }
            .store(in: &cancellables)
        
        // Auto-hide error messages
        $showError
            .filter { $0 }
            .delay(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.clearError()
            }
            .store(in: &cancellables)
    }
    
    private func updateTempGoals(from goals: NutritionGoals) {
        tempCalorieGoal = String(goals.dailyCalorieGoal)
        tempProteinGoal = String(Int(goals.proteinGoal))
        tempFatGoal = String(Int(goals.fatGoal))
        tempCarbsGoal = String(Int(goals.carbsGoal))
        tempFiberGoal = String(Int(goals.fiberGoal))
        selectedActivityLevel = goals.activityLevel
    }
    
    private func generateProgressShareText() -> String {
        var text = "🎯 My Nutrition Progress Today:\n\n"
        
        if let goals = currentGoals {
            text += "📊 Goal Completion: \(Int(todayGoalCompletion * 100))%\n"
            text += "🔥 Calories: \(dailyProgress.totalCalories)/\(goals.dailyCalorieGoal)\n"
            text += "💪 Protein: \(Int(dailyProgress.totalProtein))g/\(Int(goals.proteinGoal))g\n"
            
            if streakDays > 0 {
                text += "🔥 Current Streak: \(streakDays) days\n"
            }
            
            text += "\n✨ Tracked with Food Analyzer"
        } else {
            text += "Just started tracking my nutrition goals!\n"
            text += "✨ Using Food Analyzer to stay on track"
        }
        
        return text
    }
    
    private func showError(_ error: AppError) {
        errorMessage = error.userFriendlyMessage
        showError = true
    }
    
    private func clearError() {
        errorMessage = nil
        showError = false
    }
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccessMessage = true
    }
    
    private func hideSuccessMessage() {
        successMessage = nil
        showSuccessMessage = false
    }
    
    func saveEditingGoals() {
        let goals = NutritionGoals(
            dailyCalorieGoal: editingGoals.dailyCalorieGoal,
            proteinGoal: editingGoals.proteinGoal,
            fatGoal: editingGoals.fatGoal,
            carbsGoal: editingGoals.carbsGoal,
            fiberGoal: editingGoals.fiberGoal,
            activityLevel: selectedActivityLevel,
            goals: currentGoals?.goals ?? []
        )
        
        switch goalsRepository.saveGoals(goals) {
        case .success:
            currentGoals = goals
            isEditingGoals = false
            showSuccessMessage("Goals updated successfully! 🎯")
            loadProgress() // Refresh progress calculations
        case .failure(let error):
            showError(error)
        }
    }
    
    func startEditingGoals() {
        if let currentGoals = currentGoals {
            editingGoals.dailyCalorieGoal = currentGoals.dailyCalorieGoal
            editingGoals.proteinGoal = currentGoals.proteinGoal
            editingGoals.fatGoal = currentGoals.fatGoal
            editingGoals.carbsGoal = currentGoals.carbsGoal
            editingGoals.fiberGoal = currentGoals.fiberGoal
            selectedActivityLevel = currentGoals.activityLevel
        }
        isEditingGoals = true
    }
}

// MARK: - Supporting Types
enum ProgressPeriod: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .weekly: return "calendar.badge.plus"
        case .monthly: return "calendar.badge.clock"
        }
    }
}

struct EditableGoals {
    var dailyCalorieGoal: Int = 2000
    var proteinGoal: Double = 150.0
    var fatGoal: Double = 67.0
    var carbsGoal: Double = 250.0
    var fiberGoal: Double = 25.0
}
