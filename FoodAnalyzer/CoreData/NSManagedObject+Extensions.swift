//
//  NSManagedObject+Extensions.swift
//  FoodAnalyzer
//
//  Created on 2025-06-27.
//

import Foundation
import CoreData

// MARK: - NSManagedObject Extensions
extension NSManagedObject {
    
    // MARK: - Entity Name
    class var entityName: String {
        return String(describing: self)
    }
    
    // MARK: - Fetch Request Creation
    class func fetchRequest<T: NSManagedObject>(_ type: T.Type) -> NSFetchRequest<T> {
        return NSFetchRequest<T>(entityName: type.entityName)
    }
    
    // MARK: - Safe Value Setting
    func setValue<T>(_ value: T?, forKeyIfChanged key: String) {
        guard let value = value else { return }
        
        if let currentValue = self.value(forKey: key) as? T {
            if !isEqual(currentValue, value) {
                self.setValue(value, forKey: key)
            }
        } else {
            self.setValue(value, forKey: key)
        }
    }
    
    private func isEqual<T>(_ lhs: T, _ rhs: T) -> Bool {
        if let lhs = lhs as? AnyHashable, let rhs = rhs as? AnyHashable {
            return lhs == rhs
        }
        return false
    }
    
    // MARK: - Thread Safety
    func inContext(_ context: NSManagedObjectContext) -> Self? {
        guard !objectID.isTemporaryID else {
            do {
                try managedObjectContext?.obtainPermanentIDs(for: [self])
            } catch {
                print("Failed to obtain permanent ID: \(error)")
                return nil
            }
        }
        
        do {
            return try context.existingObject(with: objectID) as? Self
        } catch {
            print("Failed to fetch object in context: \(error)")
            return nil
        }
    }
}

// MARK: - FoodAnalysis Convenience
extension FoodAnalysis {
    
    var totalNutritionInfo: NutritionInfo {
        return NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium
        )
    }
    
    convenience init(context: NSManagedObjectContext, foodItem: FoodItem) {
        self.init(context: context)
        
        self.id = UUID()
        self.date = Date()
        self.foodName = foodItem.name
        self.confidence = foodItem.confidence
        self.servingSize = foodItem.servingSize
        self.ingredients = foodItem.ingredients?.joined(separator: ", ")
        
        // Set nutrition values
        self.calories = foodItem.nutritionInfo.calories
        self.protein = foodItem.nutritionInfo.protein
        self.carbs = foodItem.nutritionInfo.carbs
        self.fat = foodItem.nutritionInfo.fat
        self.fiber = foodItem.nutritionInfo.fiber
        self.sugar = foodItem.nutritionInfo.sugar
        self.sodium = foodItem.nutritionInfo.sodium
    }
    
    func toFoodItem() -> FoodItem {
        return FoodItem(
            name: foodName ?? "",
            confidence: confidence,
            nutritionInfo: totalNutritionInfo,
            servingSize: servingSize,
            ingredients: ingredients?.components(separatedBy: ", ").filter { !$0.isEmpty }
        )
    }
}

// MARK: - NutritionGoal Convenience
extension NutritionGoal {
    
    var nutritionTargets: NutritionInfo {
        return NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium
        )
    }
    
    convenience init(context: NSManagedObjectContext, name: String, targets: NutritionInfo) {
        self.init(context: context)
        
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = true
        
        // Set nutrition targets
        self.calories = targets.calories
        self.protein = targets.protein
        self.carbs = targets.carbs
        self.fat = targets.fat
        self.fiber = targets.fiber
        self.sugar = targets.sugar
        self.sodium = targets.sodium
    }
    
    func updateTargets(_ targets: NutritionInfo) {
        self.calories = targets.calories
        self.protein = targets.protein
        self.carbs = targets.carbs
        self.fat = targets.fat
        self.fiber = targets.fiber
        self.sugar = targets.sugar
        self.sodium = targets.sodium
        self.updatedAt = Date()
    }
}

// MARK: - User Convenience
extension User {
    
    convenience init(context: NSManagedObjectContext, profile: UserProfile) {
        self.init(context: context)
        
        self.id = UUID()
        self.name = profile.name
        self.email = profile.email
        self.age = Int16(profile.age ?? 0)
        self.gender = profile.gender
        self.height = profile.height ?? 0
        self.weight = profile.weight ?? 0
        self.activityLevel = profile.activityLevel
        self.dietaryPreferences = profile.dietaryPreferences
        self.healthGoals = profile.healthGoals
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateProfile(_ profile: UserProfile) {
        self.name = profile.name
        self.email = profile.email
        self.age = Int16(profile.age ?? 0)
        self.gender = profile.gender
        self.height = profile.height ?? 0
        self.weight = profile.weight ?? 0
        self.activityLevel = profile.activityLevel
        self.dietaryPreferences = profile.dietaryPreferences
        self.healthGoals = profile.healthGoals
        self.updatedAt = Date()
    }
    
    func toUserProfile() -> UserProfile {
        return UserProfile(
            id: id?.uuidString ?? "",
            name: name ?? "",
            email: email ?? "",
            age: Int(age),
            gender: gender,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            dietaryPreferences: dietaryPreferences,
            healthGoals: healthGoals
        )
    }
    
    var activeGoal: NutritionGoal? {
        return nutritionGoals?.compactMap { $0 as? NutritionGoal }
            .first { $0.isActive }
    }
    
    func todaysFoodAnalyses() -> [FoodAnalysis] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return foodAnalyses?.compactMap { $0 as? FoodAnalysis }
            .filter { analysis in
                guard let date = analysis.date else { return false }
                return date >= startOfDay && date < endOfDay
            }
            .sorted { ($0.date ?? Date()) > ($1.date ?? Date()) } ?? []
    }
    
    func calculateTodaysNutrition() -> NutritionInfo {
        let todaysAnalyses = todaysFoodAnalyses()
        
        let totalCalories = todaysAnalyses.reduce(0) { $0 + $1.calories }
        let totalProtein = todaysAnalyses.reduce(0) { $0 + $1.protein }
        let totalCarbs = todaysAnalyses.reduce(0) { $0 + $1.carbs }
        let totalFat = todaysAnalyses.reduce(0) { $0 + $1.fat }
        let totalFiber = todaysAnalyses.reduce(0) { $0 + $1.fiber }
        let totalSugar = todaysAnalyses.reduce(0) { $0 + $1.sugar }
        let totalSodium = todaysAnalyses.reduce(0) { $0 + $1.sodium }
        
        return NutritionInfo(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            sugar: totalSugar,
            sodium: totalSodium
        )
    }
}

// MARK: - Batch Operations
extension NSManagedObjectContext {
    
    func batchInsert<T: NSManagedObject>(_ objects: [[String: Any]], 
                                        entity: T.Type) throws {
        let entityName = String(describing: entity)
        let batchInsert = NSBatchInsertRequest(entityName: entityName, objects: objects)
        batchInsert.resultType = .objectIDs
        
        let result = try execute(batchInsert) as? NSBatchInsertResult
        
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            let changes = [NSInsertedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
        }
    }
    
    func performAndWait<T>(_ block: () throws -> T) rethrows -> T {
        var result: T!
        var blockError: Error?
        
        performAndWait {
            do {
                result = try block()
            } catch {
                blockError = error
            }
        }
        
        if let error = blockError {
            throw error
        }
        
        return result
    }
}