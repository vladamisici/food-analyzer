import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var selectedGender: UserProfile.Gender = .male
    @State private var selectedActivityLevel: NutritionGoals.ActivityLevel = .moderately
    @State private var selectedGoal: NutritionGoals.Goal.GoalType = .maintenance
    
    // Manual arrays as backup - Using correct types
    private let genderOptions: [UserProfile.Gender] = [.male, .female]
    private let activityLevelOptions: [NutritionGoals.ActivityLevel] = [.sedentary, .lightly, .moderately, .very, .extremely]
    private let goalOptions: [NutritionGoals.Goal.GoalType] = [.weightLoss, .weightGain, .maintenance, .muscle, .endurance]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Basic Info
                basicInfoSection
                
                // Gender Selection
                genderSection
                
                // Activity Level
                activityLevelSection
                
                // Goal Selection
                goalSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("Profile Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Profile Setup")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Text("Help us create personalized nutrition goals for you")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Age")
                        .font(.body)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("25", text: $age)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Text("Weight")
                        .font(.body)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("70", text: $weight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Text("kg")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Height")
                        .font(.body)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("175", text: $height)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Text("cm")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gender")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Gender", selection: $selectedGender) {
                ForEach(genderOptions, id: \.self) { gender in
                    Text(gender.displayName).tag(gender)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var activityLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Level")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(activityLevelOptions, id: \.self) { level in
                    ActivityLevelCard(
                        level: level,
                        isSelected: selectedActivityLevel == level
                    ) {
                        selectedActivityLevel = level
                    }
                }
            }
        }
    }
    
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Primary Goal")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(goalOptions, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        selectedGoal = goal
                    }
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button("Generate Recommendations") {
                generateRecommendations()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!isFormValid)
            
            Button("Skip for Now") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Properties
    
    private var isFormValid: Bool {
        !age.isEmpty && !weight.isEmpty && !height.isEmpty &&
        Int(age) != nil && Int(weight) != nil && Int(height) != nil
    }
    
    // MARK: - Actions
    
    private func generateRecommendations() {
        guard let ageValue = Int(age),
              let weightValue = Int(weight),
              let heightValue = Int(height) else {
            return
        }
        
        let profile = UserProfile(
            age: ageValue,
            weight: weightValue,
            height: heightValue,
            gender: selectedGender,
            activityLevel: selectedActivityLevel,
            goal: selectedGoal,
            preferences: nil,
            medicalConditions: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        viewModel.generateGoalRecommendations(profile: profile)
        dismiss()
    }
}

// MARK: - Supporting Views

struct ActivityLevelCard: View {
    let level: NutritionGoals.ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalCard: View {
    let goal: NutritionGoals.Goal.GoalType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extensions

extension NutritionGoals.ActivityLevel {
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightly: return "Lightly Active"
        case .moderately: return "Moderately Active"
        case .very: return "Very Active"
        case .extremely: return "Extremely Active"
        }
    }
}
#Preview {
    NavigationView {
        ProfileSetupView(viewModel: GoalsViewModel())
    }
}
