import SwiftUI

struct RecommendationsView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacing.xl) {
                // Header
                VStack(spacing: .spacing.md) {
                    Text("Personalized Recommendations")
                        .headlineLarge()
                        .foregroundColor(Color.theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Based on your profile, here are your recommended nutrition goals")
                        .bodyMedium()
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                if let recommendations = viewModel.goalRecommendations {
                    // BMR and TDEE Info
                    VStack(spacing: .spacing.lg) {
                        InfoCard(
                            title: "Basal Metabolic Rate (BMR)",
                            value: "\(recommendations.bmr) kcal/day",
                            description: "Calories your body burns at rest",
                            icon: "heart.fill",
                            color: Color.theme.accent
                        )
                        
                        InfoCard(
                            title: "Total Daily Energy Expenditure",
                            value: "\(recommendations.tdee) kcal/day",
                            description: "Calories burned including activity",
                            icon: "flame.fill",
                            color: Color.theme.primary
                        )
                    }
                    
                    // Recommended Goals
                    VStack(alignment: .leading, spacing: .spacing.md) {
                        Text("Recommended Daily Goals")
                            .titleMedium()
                            .foregroundColor(Color.theme.textPrimary)
                        
                        VStack(spacing: .spacing.md) {
                            RecommendationCard(
                                title: "Calories",
                                current: recommendations.calories,
                                unit: "kcal",
                                icon: "flame.fill",
                                color: Color.theme.primary,
                                explanation: calorieExplanation(recommendations)
                            )
                            
                            RecommendationCard(
                                title: "Protein",
                                current: Int(recommendations.protein),
                                unit: "g",
                                icon: "bolt.fill",
                                color: Color.theme.secondary,
                                explanation: "Essential for muscle maintenance and growth"
                            )
                            
                            RecommendationCard(
                                title: "Carbohydrates",
                                current: Int(recommendations.carbs),
                                unit: "g",
                                icon: "leaf.fill",
                                color: Color.theme.warning,
                                explanation: "Primary energy source for your body"
                            )
                            
                            RecommendationCard(
                                title: "Fat",
                                current: Int(recommendations.fat),
                                unit: "g",
                                icon: "drop.fill",
                                color: Color.theme.accent,
                                explanation: "Important for hormone production and nutrient absorption"
                            )
                        }
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: .spacing.md) {
                        Text("Tips for Success")
                            .titleMedium()
                            .foregroundColor(Color.theme.textPrimary)
                        
                        VStack(spacing: .spacing.sm) {
                            ForEach(recommendations.tips, id: \.self) { tip in
                                TipRow(tip: tip)
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: .spacing.md) {
                        PrimaryButton("Apply These Goals", style: .primary) {
                            viewModel.applyRecommendations()
                            dismiss()
                        }
                        
                        PrimaryButton("Customize Goals", style: .secondary) {
                            viewModel.customizeRecommendations()
                            dismiss()
                        }
                    }
                } else {
                    // Loading or Error State
                    VStack(spacing: .spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.theme.primary)
                        
                        Text("Generating recommendations...")
                            .bodyMedium()
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .containerPadding()
        }
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
    
    private func calorieExplanation(_ recommendations: GoalRecommendations) -> String {
        switch recommendations.goalType {
        case .lose:
            return "500 kcal deficit for healthy weight loss"
        case .gain:
            return "500 kcal surplus for gradual weight gain"
        case .muscle:
            return "Optimized for muscle building"
        default:
            return "Maintain your current weight"
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: .spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: .spacing.xs) {
                Text(title)
                    .bodyMedium()
                    .foregroundColor(Color.theme.textPrimary)
                    .fontWeight(.medium)
                
                Text(value)
                    .titleMedium()
                    .foregroundColor(color)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
            
            Spacer()
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct RecommendationCard: View {
    let title: String
    let current: Int
    let unit: String
    let icon: String
    let color: Color
    let explanation: String
    
    var body: some View {
        VStack(spacing: .spacing.md) {
            HStack {
                HStack(spacing: .spacing.sm) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    
                    Text(title)
                        .bodyMedium()
                        .foregroundColor(Color.theme.textPrimary)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text("\(current) \(unit)")
                    .titleMedium()
                    .foregroundColor(color)
                    .fontWeight(.bold)
            }
            
            Text(explanation)
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct TipRow: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: .spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(Color.theme.warning)
                .font(.caption)
                .offset(y: 2)
            
            Text(tip)
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.warning.opacity(0.05))
        )
    }
}

#Preview {
    NavigationView {
        RecommendationsView(viewModel: GoalsViewModel())
    }
}