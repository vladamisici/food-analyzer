import Foundation
import CoreData

@objc(NutritionGoalEntity)
public class NutritionGoalEntity: NSManagedObject {
    
    // MARK: - Lifecycle
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Set default values when entity is first created
        if id == nil {
            id = UUID()
        }
        
        if createdAt == nil {
            createdAt = Date()
        }
        
        if updatedAt == nil {
            updatedAt = Date()
        }
    }
    
    public override func willSave() {
        super.willSave()
        
        // Always update the updatedAt timestamp when saving
        if !isDeleted {
            updatedAt = Date()
        }
    }
}
