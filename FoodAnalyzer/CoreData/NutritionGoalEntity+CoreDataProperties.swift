import Foundation
import CoreData

extension NutritionGoalEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NutritionGoalEntity> {
        return NSFetchRequest<NutritionGoalEntity>(entityName: "NutritionGoalEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var userId: String?
    @NSManaged public var calories: Double
    @NSManaged public var protein: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fat: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension NutritionGoalEntity : Identifiable {
    
}

// MARK: - Conversion Methods
extension NutritionGoalEntity {
    
    /// Convert Core Data entity to NutritionGoals model
    func toNutritionGoals() -> NutritionGoals {
        return NutritionGoals(
            dailyCalorieGoal: Int(calories),
            proteinGoal: protein,
            fatGoal: fat,
            carbsGoal: carbs,
            fiberGoal: 25.0, // Default value
            activityLevel: .moderately, // Default value
            goals: [] // Default empty array
        )
    }
    
    /// Create Core Data entity from NutritionGoals model
    static func from(_ goals: NutritionGoals, userId: String, in context: NSManagedObjectContext) -> NutritionGoalEntity {
        let entity = NutritionGoalEntity(context: context)
        entity.id = UUID()
        entity.userId = userId
        entity.calories = Double(goals.dailyCalorieGoal)
        entity.protein = goals.proteinGoal
        entity.carbs = goals.carbsGoal
        entity.fat = goals.fatGoal
        entity.createdAt = Date()
        entity.updatedAt = Date()
        return entity
    }
    
    /// Update existing entity with new values from NutritionGoals
    func update(from goals: NutritionGoals) {
        self.calories = Double(goals.dailyCalorieGoal)
        self.protein = goals.proteinGoal
        self.carbs = goals.carbsGoal
        self.fat = goals.fatGoal
        self.updatedAt = Date()
    }
}

// MARK: - Convenience Methods
extension NutritionGoalEntity {
    
    /// Check if the entity has valid data
    var isValid: Bool {
        return calories > 0 && protein > 0 && carbs > 0 && fat > 0
    }
    
    /// Get formatted description
    public override var description: String {
        return "Calories: \(Int(calories)), Protein: \(protein)g, Carbs: \(carbs)g, Fat: \(fat)g"
    }
    
    /// Create or update nutrition goal for user
    static func createOrUpdate(goals: NutritionGoals, userId: String, in context: NSManagedObjectContext) throws -> NutritionGoalEntity {
        let request: NSFetchRequest<NutritionGoalEntity> = NutritionGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.fetchLimit = 1
        
        if let existingEntity = try context.fetch(request).first {
            existingEntity.update(from: goals)
            return existingEntity
        } else {
            return NutritionGoalEntity.from(goals, userId: userId, in: context)
        }
    }
    
    /// Fetch nutrition goals for user
    static func fetchGoals(for userId: String, in context: NSManagedObjectContext) throws -> NutritionGoalEntity? {
        let request: NSFetchRequest<NutritionGoalEntity> = NutritionGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    /// Fetch nutrition goals as model for user
    static func fetchNutritionGoals(for userId: String, in context: NSManagedObjectContext) throws -> NutritionGoals? {
        return try fetchGoals(for: userId, in: context)?.toNutritionGoals()
    }
}

// MARK: - Additional Helper Methods
extension NutritionGoalEntity {
    
    /// Calculate macro ratios
    var macroRatios: (protein: Double, carbs: Double, fat: Double) {
        let totalMacroCalories = (protein * 4) + (carbs * 4) + (fat * 9)
        guard totalMacroCalories > 0 else { return (0, 0, 0) }
        
        return (
            protein: (protein * 4) / totalMacroCalories,
            carbs: (carbs * 4) / totalMacroCalories,
            fat: (fat * 9) / totalMacroCalories
        )
    }
    
    /// Check if goals are realistic
    var areGoalsRealistic: Bool {
        let totalMacroCalories = (protein * 4) + (carbs * 4) + (fat * 9)
        let caloriesDifference = abs(calories - totalMacroCalories)
        return caloriesDifference <= (calories * 0.1) // Within 10% tolerance
    }
}
