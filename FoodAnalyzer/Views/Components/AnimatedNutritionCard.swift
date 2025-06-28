import SwiftUI

struct AnimatedNutritionCard: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    let icon: String
    let progress: Double
    
    @State private var isAnimating = false
    @State private var progressValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.theme.textSecondary)
                
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(Int(value))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(), value: value)
                
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.theme.textSecondary)
                    .offset(y: -4)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressValue, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressValue)
                    
                    if progressValue > 0.95 {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                                .padding(.trailing, 4)
                        }
                    }
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.surface)
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isAnimating ? 1 : 0.95)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                isAnimating = true
                progressValue = min(progress, 1.0)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating.toggle()
            }
        }
    }
}

struct AnimatedNutritionGrid: View {
    let nutritionData: (calories: Double, protein: Double, carbs: Double, fat: Double)
    let goals: NutritionGoals?
    @State private var selectedCard: String? = nil
    
    // Convenience initializers for different data sources
    init(from analysis: FoodAnalysisResponse, goals: NutritionGoals? = nil) {
        self.nutritionData = analysis.simpleNutrition
        self.goals = goals
    }
    
    init(from dailyProgress: DailyProgress, goals: NutritionGoals? = nil) {
        self.nutritionData = dailyProgress.nutritionSummary
        self.goals = goals
    }
    
    init(from analyses: [FoodAnalysisResponse], goals: NutritionGoals? = nil) {
        self.nutritionData = analyses.aggregatedNutrition
        self.goals = goals
    }
    
    // Direct initializer
    init(calories: Double, protein: Double, carbs: Double, fat: Double, goals: NutritionGoals? = nil) {
        self.nutritionData = (calories: calories, protein: protein, carbs: carbs, fat: fat)
        self.goals = goals
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            AnimatedNutritionCard(
                title: "Calories",
                value: nutritionData.calories,
                unit: "kcal",
                color: .orange,
                icon: "flame.fill",
                progress: goals != nil ? nutritionData.calories / goals!.dailyCalories : 0
            )
            .slideIn(delay: 0.1)
            .onTapGesture {
                selectedCard = "calories"
                HapticManager.shared.impact(.light)
            }
            .scaleEffect(selectedCard == "calories" ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCard)
            
            AnimatedNutritionCard(
                title: "Protein",
                value: nutritionData.protein,
                unit: "g",
                color: .blue,
                icon: "bolt.fill",
                progress: goals != nil ? nutritionData.protein / goals!.dailyProtein : 0
            )
            .slideIn(delay: 0.2)
            .onTapGesture {
                selectedCard = "protein"
                HapticManager.shared.impact(.light)
            }
            .scaleEffect(selectedCard == "protein" ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCard)
            
            AnimatedNutritionCard(
                title: "Carbs",
                value: nutritionData.carbs,
                unit: "g",
                color: .green,
                icon: "leaf.fill",
                progress: goals != nil ? nutritionData.carbs / goals!.dailyCarbs : 0
            )
            .slideIn(delay: 0.3)
            .onTapGesture {
                selectedCard = "carbs"
                HapticManager.shared.impact(.light)
            }
            .scaleEffect(selectedCard == "carbs" ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCard)
            
            AnimatedNutritionCard(
                title: "Fat",
                value: nutritionData.fat,
                unit: "g",
                color: .purple,
                icon: "drop.fill",
                progress: goals != nil ? nutritionData.fat / goals!.dailyFat : 0
            )
            .slideIn(delay: 0.4)
            .onTapGesture {
                selectedCard = "fat"
                HapticManager.shared.impact(.light)
            }
            .scaleEffect(selectedCard == "fat" ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCard)
        }
        .onAppear {
            selectedCard = nil
        }
    }
}


#Preview {
    VStack {
        AnimatedNutritionGrid(
            calories: 450,
            protein: 25,
            carbs: 60,
            fat: 15,
            goals: NutritionGoals(
                id: UUID(),
                dailyCalorieGoal: 2000,
                proteinGoal: 50,
                fatGoal: 65,
                carbsGoal: 250,
                fiberGoal: 25,
                activityLevel: .moderately,
                goals: []
            )
        )
        .padding()
    }
    .background(Color.theme.background)
}
