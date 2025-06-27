//
//  CoreDataModels.swift
//  FoodAnalyzer
//
//  Created on 2025-06-27.
//

import Foundation

// MARK: - Core Data Supporting Models
// These models bridge between Core Data entities and the app's domain models

struct NutritionInfo: Codable, Equatable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    
    static var zero: NutritionInfo {
        return NutritionInfo(
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0
        )
    }
    
    static var defaultGoals: NutritionInfo {
        return NutritionInfo(
            calories: 2000,
            protein: 50,
            carbs: 300,
            fat: 65,
            fiber: 25,
            sugar: 50,
            sodium: 2300
        )
    }
}

struct FoodItem: Codable, Identifiable {
    let id = UUID()
    let name: String
    let confidence: Double
    let nutritionInfo: NutritionInfo
    let servingSize: String?
    let ingredients: [String]?
    
    init(name: String,
         confidence: Double,
         nutritionInfo: NutritionInfo,
         servingSize: String? = nil,
         ingredients: [String]? = nil) {
        self.name = name
        self.confidence = confidence
        self.nutritionInfo = nutritionInfo
        self.servingSize = servingSize
        self.ingredients = ingredients
    }
    
    // Convert from API response
    init(from response: FoodAnalysisResponse) {
        self.name = response.itemName
        self.confidence = response.confidence
        self.nutritionInfo = NutritionInfo(
            calories: Double(response.calories),
            protein: response.proteinValue,
            carbs: response.carbsValue,
            fat: response.fatValue,
            fiber: response.fiber ?? 0,
            sugar: response.sugar ?? 0,
            sodium: response.sodium ?? 0
        )
        self.servingSize = nil
        self.ingredients = nil
    }
}

struct UserProfile: Codable {
    let id: String
    let name: String
    let email: String
    let age: Int?
    let gender: String?
    let height: Double?
    let weight: Double?
    let activityLevel: String?
    let dietaryPreferences: [String]?
    let healthGoals: [String]?
    
    init(id: String,
         name: String,
         email: String,
         age: Int? = nil,
         gender: String? = nil,
         height: Double? = nil,
         weight: Double? = nil,
         activityLevel: String? = nil,
         dietaryPreferences: [String]? = nil,
         healthGoals: [String]? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
        self.dietaryPreferences = dietaryPreferences
        self.healthGoals = healthGoals
    }
}

// MARK: - Nutrition Calculation Helpers
extension NutritionInfo {
    
    var totalCaloriesFromMacros: Double {
        return (protein * 4) + (carbs * 4) + (fat * 9)
    }
    
    var macroPercentages: (protein: Double, carbs: Double, fat: Double) {
        let total = totalCaloriesFromMacros
        guard total > 0 else { return (0, 0, 0) }
        
        let proteinPercent = (protein * 4 / total) * 100
        let carbsPercent = (carbs * 4 / total) * 100
        let fatPercent = (fat * 9 / total) * 100
        
        return (proteinPercent, carbsPercent, fatPercent)
    }
    
    func progress(against goal: NutritionInfo) -> [String: Double] {
        return [
            "calories": goal.calories > 0 ? calories / goal.calories : 0,
            "protein": goal.protein > 0 ? protein / goal.protein : 0,
            "carbs": goal.carbs > 0 ? carbs / goal.carbs : 0,
            "fat": goal.fat > 0 ? fat / goal.fat : 0,
            "fiber": goal.fiber > 0 ? fiber / goal.fiber : 0,
            "sugar": goal.sugar > 0 ? sugar / goal.sugar : 0,
            "sodium": goal.sodium > 0 ? sodium / goal.sodium : 0
        ]
    }
    
    static func +(lhs: NutritionInfo, rhs: NutritionInfo) -> NutritionInfo {
        return NutritionInfo(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sugar: lhs.sugar + rhs.sugar,
            sodium: lhs.sodium + rhs.sodium
        )
    }
}