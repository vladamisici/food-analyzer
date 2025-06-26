import SwiftUI

struct AchievementsView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: Achievement.AchievementCategory?
    
    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return viewModel.achievements.filter { $0.category == category }
        }
        return viewModel.achievements
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Filter
            AchievementCategoryFilterView(selectedCategory: $selectedCategory)
                .padding(.vertical, .spacing.md)
            
            // Achievements List
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.lg) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .containerPadding()
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AchievementsView(viewModel: GoalsViewModel())
    }
}