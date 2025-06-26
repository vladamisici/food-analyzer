import Foundation

struct User: Codable {
    let id: String?
    let email: String
    let firstName: String?
    let lastName: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

struct FoodAnalysisRequest: Codable {
    let image: String
}

struct FoodAnalysisResponse: Codable {
    let itemName: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let healthScore: Int
    let coachComment: String
}