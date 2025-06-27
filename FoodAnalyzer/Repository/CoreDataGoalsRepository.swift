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
    
    func saveGoals(_ goals: NutritionGoals) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.authentication(.unauthorized)
        }
        
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
    }
    
    func getGoals() async throws -> NutritionGoals? {
        guard let userId = currentUser?.id else {
            throw AppError.authentication(.unauthorized)
        }
        
        return try await coreDataManager.performBackgroundTask { context in
            let request = NutritionGoalEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId)
            
            if let entity = try context.fetch(request).first {
                return entity.toNutritionGoals()
            }
            
            return nil
        }
    }
    
    func deleteGoals() async throws {
        guard let userId = currentUser?.id else {
            throw AppError.authentication(.unauthorized)
        }
        
        try await coreDataManager.performBackgroundTask { context in
            let request = NutritionGoalEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId)
            
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
            }
        }
    }
    
    // MARK: - Protocol conformance methods
    func saveGoals(_ goals: NutritionGoals) -> AppResult<Void> {
        let semaphore = DispatchSemaphore(value: 0)
        var result: AppResult<Void> = .success(())
        
        Task {
            do {
                try await saveGoals(goals)
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
        let semaphore = DispatchSemaphore(value: 0)
        var result: AppResult<NutritionGoals?> = .success(nil)
        
        Task {
            do {
                let goals = try await getGoals()
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
        // For now, just return success - would implement actual progress tracking
        return .success(())
    }
    
    func getDailyProgress(for date: Date) -> AppResult<DailyProgress> {
        return .success(DailyProgress.empty)
    }
    
    func getWeeklyProgress() -> AppResult<WeeklyProgress> {
        return .success(WeeklyProgress(days: [], totalCalories: 0, averageCalories: 0))
    }
    
    func getMonthlyProgress() -> AppResult<MonthlyProgress> {
        return .success(MonthlyProgress(weeks: [], totalCalories: 0, averageCalories: 0))
    }
    
    func getAchievements() -> AppResult<[Achievement]> {
        return .success([])
    }
    
    func generateGoalRecommendations(userProfile: UserProfile) -> AppResult<GoalRecommendations> {
        return .success(GoalRecommendations(
            calorieGoal: 2000,
            proteinGoal: 50,
            carbGoal: 250,
            fatGoal: 65,
            reasoning: "Based on your profile"
        ))
    }
}