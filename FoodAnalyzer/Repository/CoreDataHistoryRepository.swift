import Foundation
import CoreData
import Combine

class CoreDataHistoryRepository: HistoryRepositoryProtocol {
    private let coreDataManager = CoreDataManager.shared
    private let currentUserSubject = CurrentValueSubject<User?, Never>(nil)
    
    var currentUser: User? {
        get { currentUserSubject.value }
        set { currentUserSubject.send(newValue) }
    }
    
    func saveAnalysis(_ analysis: FoodAnalysisResponse, imageData: Data?) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.unauthorized
        }
        
        try await coreDataManager.performBackgroundTask { context in
            _ = FoodAnalysisEntity.from(analysis, userId: userId, imageData: imageData, in: context)
            try context.save()
        }
    }
    
    func getHistory() async throws -> [HistoryItem] {
        guard let userId = currentUser?.id else {
            throw AppError.unauthorized
        }
        
        return try await coreDataManager.performBackgroundTask { context in
            let request = FoodAnalysisEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(request)
            
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let createdAt = entity.createdAt else {
                    return nil
                }
                
                return HistoryItem(
                    id: id,
                    analysis: entity.toFoodAnalysisResponse(),
                    imageData: entity.imageData,
                    date: createdAt
                )
            }
        }
    }
    
    func deleteHistoryItem(_ id: UUID) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.unauthorized
        }
        
        try await coreDataManager.performBackgroundTask { context in
            let request = FoodAnalysisEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@ AND userId == %@", id as CVarArg, userId)
            
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
            }
        }
    }
    
    func clearHistory() async throws {
        guard let userId = currentUser?.id else {
            throw AppError.unauthorized
        }
        
        try await coreDataManager.performBackgroundTask { context in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FoodAnalysisEntity")
            request.predicate = NSPredicate(format: "userId == %@", userId)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
            try context.save()
        }
    }
    
    func getHistoryForDateRange(from startDate: Date, to endDate: Date) async throws -> [HistoryItem] {
        guard let userId = currentUser?.id else {
            throw AppError.unauthorized
        }
        
        return try await coreDataManager.performBackgroundTask { context in
            let request = FoodAnalysisEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "userId == %@ AND createdAt >= %@ AND createdAt <= %@",
                userId, startDate as NSDate, endDate as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(request)
            
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let createdAt = entity.createdAt else {
                    return nil
                }
                
                return HistoryItem(
                    id: id,
                    analysis: entity.toFoodAnalysisResponse(),
                    imageData: entity.imageData,
                    date: createdAt
                )
            }
        }
    }
}