import Foundation
import CoreData

extension FoodAnalysisEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodAnalysisEntity> {
        return NSFetchRequest<FoodAnalysisEntity>(entityName: "FoodAnalysisEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var userId: String?
    @NSManaged public var foodName: String?
    @NSManaged public var calories: Double
    @NSManaged public var protein: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fat: Double
    @NSManaged public var healthScore: Int16
    @NSManaged public var coachingComments: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var createdAt: Date?
}

extension FoodAnalysisEntity : Identifiable {
    
}

extension FoodAnalysisEntity {
    func toFoodAnalysisResponse() -> FoodAnalysisResponse {
        return FoodAnalysisResponse(
            id: id?.uuidString ?? UUID().uuidString,
            itemName: foodName ?? "",
            calories: Int(calories),
            protein: "\(Int(protein))g",
            fat: "\(Int(fat))g",
            carbs: "\(Int(carbs))g",
            healthScore: healthScoreToString(Int(healthScore)),
            coachComment: coachingComments ?? "",
            analyzedAt: ISO8601DateFormatter().string(from: createdAt ?? Date())
        )
    }
    
    private func healthScoreToString(_ score: Int) -> String {
        switch score {
        case 8...10: return "Healthy"
        case 6...7: return "Good"
        case 4...5: return "Fair"
        default: return "Poor"
        }
    }
    
    static func from(_ response: FoodAnalysisResponse, userId: String, imageData: Data?, in context: NSManagedObjectContext) -> FoodAnalysisEntity {
        let entity = FoodAnalysisEntity(context: context)
        entity.id = UUID()
        entity.userId = userId
        entity.foodName = response.itemName
        entity.calories = Double(response.calories)
        entity.protein = response.proteinValue
        entity.carbs = response.carbsValue
        entity.fat = response.fatValue
        entity.healthScore = Int16(response.healthScoreValue)
        entity.coachingComments = response.coachComment
        entity.imageData = imageData
        entity.createdAt = Date()
        return entity
    }
}