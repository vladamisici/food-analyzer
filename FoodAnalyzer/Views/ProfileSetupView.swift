import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var selectedGender: UserProfile.Gender = .male
    @State private var selectedActivityLevel: UserProfile.ActivityLevel = .moderately
    @State private var selectedGoal: UserProfile.Goal = .maintenance
    
    // Manual arrays as backup if .allCases doesn't work
    private let genderOptions: [UserProfile.Gender] = [.male, .female]
    private let activityLevelOptions: [UserProfile.ActivityLevel] = [.sedentary, .lightly, .moderately, .very, .extremely]
    private let goalOptions: [UserProfile.Goal] = [.weightLoss, .weightGain, .maintenance, .muscle, .endurance]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Profile Setup")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("Help us create personalized nutrition goals for you")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Basic Info
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
                
                // Gender Selection - Using manual array
                VStack(alignment: .leading, spacing: 16) {
                    Text("Gender")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Gender", selection: $selectedGender) {
                        ForEach(genderOptions, id: \.self) { gender in
                            Text(gender.rawValue.capitalized).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Activity Level - Using manual array
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
                
                // Goal Selection - Using manual array
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
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button("Generate Recommendations") {
                        generateRecommendations()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
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
            .padding()
        }
        .navigationTitle("Profile Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
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
            goal: selectedGoal
        )
        
        viewModel.generateGoalRecommendations(profile: profile)
        dismiss()
    }
}

struct ActivityLevelCard: View {
    let level: UserProfile.ActivityLevel
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
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
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
    let goal: UserProfile.Goal
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
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
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
extension UserProfile.ActivityLevel {
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightly: return "Lightly Active"
        case .moderately: return "Moderately Active"
        case .very: return "Very Active"
        case .extremely: return "Extremely Active"
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .lightly: return "Light exercise 1-3 days/week"
        case .moderately: return "Moderate exercise 3-5 days/week"
        case .very: return "Heavy exercise 6-7 days/week"
        case .extremely: return "Physical job + exercise"
        }
    }
}

extension UserProfile.Goal {
    var displayName: String {
        switch self {
        case .weightLoss: return "Lose Weight"
        case .maintenance: return "Maintain Weight"
        case .weightGain: return "Gain Weight"
        case .muscle: return "Build Muscle"
        case .endurance: return "Improve Endurance"
        }
    }
    
    var description: String {
        switch self {
        case .weightLoss: return "Create a calorie deficit"
        case .maintenance: return "Balance calories in/out"
        case .weightGain: return "Create a calorie surplus"
        case .muscle: return "High protein, strength focus"
        case .endurance: return "Focus on stamina and cardio"
        }
    }
}

#Preview {
    NavigationView {
        ProfileSetupView(viewModel: GoalsViewModel())
    }
}
