import SwiftUI

struct NutritionCard: View {
    let analysis: FoodAnalysisResponse
    let onEdit: ((FoodAnalysisResponse) -> Void)?
    let onShare: ((FoodAnalysisResponse) -> Void)?
    
    @State private var isExpanded = false
    @State private var showingEditSheet = false
    
    init(
        analysis: FoodAnalysisResponse,
        onEdit: ((FoodAnalysisResponse) -> Void)? = nil,
        onShare: ((FoodAnalysisResponse) -> Void)? = nil
    ) {
        self.analysis = analysis
        self.onEdit = onEdit
        self.onShare = onShare
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            // Main Content
            mainContent
            
            // Expanded Content
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // Actions
            actions
        }
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadiusLarge)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.theme.textPrimary.opacity(0.08),
                    radius: 20,
                    x: 0,
                    y: 8
                )
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacing.xs) {
                Text(analysis.itemName)
                    .titleLarge()
                    .lineLimit(2)
                
                Text(formatDate(analysis.analysisDate))
                    .labelMedium()
                    .foregroundColor(Color.theme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: .spacing.xs) {
                // Health Score Badge
                healthScoreBadge
                
                // Nutrition Grade
                nutritionGradeBadge
            }
        }
        .cardPadding()
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: .spacing.md) {
            // Calories and Macros
            HStack(spacing: .spacing.lg) {
                // Calories
                VStack(spacing: .spacing.xs) {
                    Text("\(analysis.calories)")
                        .font(.theme.headlineMedium)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.primary)
                    
                    Text("Calories")
                        .labelMedium()
                }
                
                Divider()
                    .frame(height: 40)
                
                // Macros Grid
                macrosGrid
            }
            .cardPadding()
            
            // Progress Rings
            if !isExpanded {
                macroProgressRings
                    .cardPadding()
            }
        }
    }
    
    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(spacing: .spacing.md) {
            Divider()
                .padding(.horizontal, .spacing.cardPadding)
            
            // Detailed Nutrition
            detailedNutrition
            
            // Coach Comment
            if !analysis.coachComment.isEmpty {
                coachComment
            }
            
            // Insights
            if !analysis.insights.isEmpty {
                insights
            }
        }
    }
    
    // MARK: - Actions
    private var actions: some View {
        HStack(spacing: .spacing.md) {
            // Expand/Collapse Button
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: .spacing.xs) {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .labelMedium()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(Color.theme.primary)
            }
            
            Spacer()
            
            // Action Buttons
            if let onEdit = onEdit {
                Button(action: { onEdit(analysis) }) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color.theme.secondary)
                }
            }
            
            if let onShare = onShare {
                Button(action: { onShare(analysis) }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color.theme.primary)
                }
            }
        }
        .cardPadding()
    }
    
    // MARK: - Components
    private var healthScoreBadge: some View {
        HStack(spacing: .spacing.xs) {
            Image(systemName: "heart.fill")
                .foregroundColor(healthScoreColor)
                .font(.caption)
            
            Text(analysis.healthScore)
                .labelMedium(healthScoreColor)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, .spacing.sm)
        .padding(.vertical, .spacing.xs)
        .background(
            Capsule()
                .fill(healthScoreColor.opacity(0.1))
        )
    }
    
    private var nutritionGradeBadge: some View {
        Text(analysis.nutritionGrade.rawValue)
            .labelMedium()
            .fontWeight(.bold)
            .foregroundColor(Color(hex: analysis.nutritionGrade.color))
            .padding(.horizontal, .spacing.sm)
            .padding(.vertical, .spacing.xs)
            .background(
                Capsule()
                    .fill(Color(hex: analysis.nutritionGrade.color).opacity(0.1))
            )
    }
    
    private var macrosGrid: some View {
        HStack(spacing: .spacing.md) {
            macroItem("Protein", value: analysis.proteinValue, unit: "g", color: Color.theme.secondary)
            macroItem("Fat", value: analysis.fatValue, unit: "g", color: Color.theme.warning)
            macroItem("Carbs", value: analysis.carbsValue, unit: "g", color: Color.theme.primary)
        }
    }
    
    private func macroItem(_ name: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: .spacing.xs) {
            Text(String(format: "%.1f", value))
                .font(.theme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text("\(name)")
                .labelMedium()
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(Color.theme.textTertiary)
        }
    }
    
    private var macroProgressRings: some View {
        HStack(spacing: .spacing.xl) {
            macroRing("P", value: analysis.proteinValue, color: Color.theme.secondary)
            macroRing("F", value: analysis.fatValue, color: Color.theme.warning)
            macroRing("C", value: analysis.carbsValue, color: Color.theme.primary)
        }
    }
    
    private func macroRing(_ letter: String, value: Double, color: Color) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: min(value / 100, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: value)
            
            Text(letter)
                .font(.theme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
    
    private var detailedNutrition: some View {
        VStack(spacing: .spacing.sm) {
            Text("Detailed Nutrition")
                .titleMedium()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.sm) {
                if let fiber = analysis.fiber {
                    nutritionDetailItem("Fiber", value: fiber, unit: "g")
                }
                if let sugar = analysis.sugar {
                    nutritionDetailItem("Sugar", value: sugar, unit: "g")
                }
                if let sodium = analysis.sodium {
                    nutritionDetailItem("Sodium", value: sodium, unit: "mg")
                }
                nutritionDetailItem("Confidence", value: analysis.confidence * 100, unit: "%")
            }
        }
        .cardPadding()
    }
    
    private func nutritionDetailItem(_ name: String, value: Double, unit: String) -> some View {
        HStack {
            Text(name)
                .bodyMedium()
            
            Spacer()
            
            Text("\(String(format: "%.1f", value)) \(unit)")
                .bodyMedium()
                .fontWeight(.medium)
        }
        .padding(.vertical, .spacing.xs)
    }
    
    private var coachComment: some View {
        VStack(alignment: .leading, spacing: .spacing.sm) {
            Text("Coach Insights")
                .titleMedium()
            
            Text(analysis.coachComment)
                .bodyMedium()
                .multilineTextAlignment(.leading)
                .cardPadding()
                .background(
                    RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                        .fill(Color.theme.background)
                )
        }
        .cardPadding()
    }
    
    private var insights: some View {
        VStack(alignment: .leading, spacing: .spacing.sm) {
            Text("Insights")
                .titleMedium()
            
            ForEach(analysis.insights) { insight in
                insightRow(insight)
            }
        }
        .cardPadding()
    }
    
    private func insightRow(_ insight: FoodAnalysisResponse.NutritionInsight) -> some View {
        HStack(spacing: .spacing.sm) {
            Image(systemName: insightIcon(for: insight.type))
                .foregroundColor(Color(hex: insight.severity.color))
                .frame(width: .spacing.iconSM)
            
            Text(insight.message)
                .bodyMedium()
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, .spacing.xs)
    }
    
    // MARK: - Computed Properties
    private var healthScoreColor: Color {
        switch analysis.healthScore.lowercased() {
        case "healthy", "excellent":
            return Color.theme.success
        case "good":
            return Color.theme.primary
        case "fair", "moderate":
            return Color.theme.warning
        default:
            return Color.theme.error
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func insightIcon(for type: FoodAnalysisResponse.NutritionInsight.InsightType) -> String {
        switch type {
        case .highSodium: return "exclamationmark.triangle"
        case .lowProtein: return "info.circle"
        case .highSugar: return "exclamationmark.triangle"
        case .goodFiber: return "checkmark.circle"
        case .balanced: return "checkmark.circle"
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: .spacing.lg) {
            NutritionCard(
                analysis: FoodAnalysisResponse(
                    id: "1",
                    itemName: "Grilled Chicken Salad with Avocado",
                    calories: 420,
                    protein: "35g",
                    fat: "18g", 
                    carbs: "26g",
                    healthScore: "Healthy",
                    coachComment: "Excellent choice! This meal provides high-quality protein and healthy fats while keeping calories moderate.",
                    analyzedAt: "2025-06-26T17:54:00.095Z"
                ),
                onEdit: { _ in },
                onShare: { _ in }
            )
        }
        .containerPadding()
    }
}
