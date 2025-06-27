import Foundation

struct Nutrition: Codable, Equatable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    init(calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    
    init(from response: FoodAnalysisResponse) {
        self.calories = Double(response.calories)
        self.protein = response.proteinValue
        self.carbs = response.carbsValue
        self.fat = response.fatValue
    }
}