import SwiftUI

struct GoalEditingView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: .spacing.xl) {
                // Daily Calorie Goal
                VStack(alignment: .leading, spacing: .spacing.md) {
                    Text("Daily Calorie Goal")
                        .titleMedium()
                        .foregroundColor(Color.theme.textPrimary)
                    
                    HStack {
                        TextField("2000", value: $viewModel.editingGoals.dailyCalorieGoal, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("kcal")
                            .bodyMedium()
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
                
                // Macro Goals
                VStack(alignment: .leading, spacing: .spacing.lg) {
                    Text("Macronutrient Goals")
                        .titleMedium()
                        .foregroundColor(Color.theme.textPrimary)
                    
                    MacroGoalEditor(
                        title: "Protein",
                        value: $viewModel.editingGoals.proteinGoal,
                        unit: "g",
                        color: Color.theme.secondary
                    )
                    
                    MacroGoalEditor(
                        title: "Carbohydrates",
                        value: $viewModel.editingGoals.carbsGoal,
                        unit: "g",
                        color: Color.theme.warning
                    )
                    
                    MacroGoalEditor(
                        title: "Fat",
                        value: $viewModel.editingGoals.fatGoal,
                        unit: "g",
                        color: Color.theme.accent
                    )
                }
                
                // Action Buttons
                VStack(spacing: .spacing.md) {
                    PrimaryButton("Save Goals", style: .primary) {
                        viewModel.saveEditingGoals()
                        dismiss()
                    }
                    
                    PrimaryButton("Cancel", style: .secondary) {
                        dismiss()
                    }
                }
            }
            .containerPadding()
        }
        .navigationTitle("Edit Goals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MacroGoalEditor: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing.sm) {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .bodyMedium()
                    .foregroundColor(Color.theme.textPrimary)
            }
            
            HStack {
                TextField("0", value: $value, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text(unit)
                    .bodyMedium()
                    .foregroundColor(Color.theme.textSecondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        GoalEditingView(viewModel: GoalsViewModel())
    }
}