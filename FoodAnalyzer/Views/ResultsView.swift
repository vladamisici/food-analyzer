import SwiftUI

struct ResultsView: View {
    @State private var result: FoodAnalysisResponse
    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedCalories: String
    
    init(result: FoodAnalysisResponse) {
        self._result = State(initialValue: result)
        self._editedName = State(initialValue: result.itemName)
        self._editedCalories = State(initialValue: String(result.calories))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Analysis Results")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
                .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                if isEditing {
                    HStack {
                        Text("Food:")
                            .fontWeight(.medium)
                        TextField("Food name", text: $editedName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Calories:")
                            .fontWeight(.medium)
                        TextField("Calories", text: $editedCalories)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                } else {
                    HStack {
                        Text("Food:")
                            .fontWeight(.medium)
                        Text(result.itemName)
                    }
                    
                    HStack {
                        Text("Calories:")
                            .fontWeight(.medium)
                        Text("\(result.calories)")
                    }
                }
                
                HStack {
                    Text("Protein:")
                        .fontWeight(.medium)
                    Text(result.protein)
                }
                
                HStack {
                    Text("Fat:")
                        .fontWeight(.medium)
                    Text(result.fat)
                }
                
                HStack {
                    Text("Carbs:")
                        .fontWeight(.medium)
                    Text(result.carbs)
                }
                
                HStack {
                    Text("Health Score:")
                        .fontWeight(.medium)
                    Text(result.healthScore)
                        .foregroundColor(healthScoreColor)
                }
                
                if !result.coachComment.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Coach Comment:")
                            .fontWeight(.medium)
                        Text(result.coachComment)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var healthScoreColor: Color {
        switch result.healthScore.lowercased() {
        case "healthy", "excellent":
            return .green
        case "good":
            return .orange
        case "fair", "moderate":
            return .yellow
        default:
            return .red
        }
    }
    
    private func saveChanges() {
        result.itemName = editedName
        result.calories = Int(editedCalories) ?? result.calories
    }
}
