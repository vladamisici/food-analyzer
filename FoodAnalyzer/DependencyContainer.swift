import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    lazy var authRepository: AuthRepositoryProtocol = AuthRepository()
    
    lazy var historyRepository: HistoryRepositoryProtocol = {
        return CoreDataHistoryRepository()
    }()
    
    lazy var goalsRepository: GoalsRepositoryProtocol = {
        return CoreDataGoalsRepository()
    }()
    
    func setupUserForRepositories(_ user: User?) {
        if let coreDataHistory = historyRepository as? CoreDataHistoryRepository {
            coreDataHistory.currentUser = user
        }
        if let coreDataGoals = goalsRepository as? CoreDataGoalsRepository {
            coreDataGoals.currentUser = user
        }
    }
}