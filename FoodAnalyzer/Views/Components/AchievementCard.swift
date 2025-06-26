import SwiftUI

struct AchievementCard: View {
    let achievement: Achievement
    let isCompact: Bool
    
    @State private var showDetails = false
    @State private var animateUnlock = false
    
    init(achievement: Achievement, isCompact: Bool = false) {
        self.achievement = achievement
        self.isCompact = isCompact
    }
    
    var body: some View {
        if isCompact {
            compactView
        } else {
            fullView
        }
    }
    
    private var compactView: some View {
        HStack(spacing: .spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.category.color.opacity(0.2) : Color.theme.textTertiary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievement.isUnlocked ? achievement.category.color : Color.theme.textTertiary)
                    .scaleEffect(animateUnlock ? 1.2 : 1.0)
            }
            
            // Content
            VStack(alignment: .leading, spacing: .spacing.xs) {
                Text(achievement.title)
                    .labelMedium()
                    .foregroundColor(achievement.isUnlocked ? Color.theme.textPrimary : Color.theme.textTertiary)
                    .fontWeight(.semibold)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                // Unlock date
                Text(formatUnlockDate(achievement.unlockedAt))
                    .font(.caption2)
                    .foregroundColor(Color.theme.textTertiary)
            } else {
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(Color.theme.textTertiary)
            }
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(achievement.isUnlocked ? Color.theme.surface : Color.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                        .strokeBorder(
                            achievement.isUnlocked ? achievement.category.color.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .onTapGesture {
            showDetails = true
        }
        .onAppear {
            if achievement.isUnlocked {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateUnlock = true
                }
            }
        }
    }
    
    private var fullView: some View {
        VStack(spacing: .spacing.md) {
            // Header
            HStack {
                // Category badge
                Text(achievement.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(achievement.category.color)
                    .padding(.horizontal, .spacing.sm)
                    .padding(.vertical, .spacing.xs)
                    .background(
                        Capsule()
                            .fill(achievement.category.color.opacity(0.15))
                    )
                
                Spacer()
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.theme.success)
                        .font(.title3)
                }
            }
            
            // Icon and content
            VStack(spacing: .spacing.md) {
                // Large icon
                ZStack {
                    Circle()
                        .fill(
                            achievement.isUnlocked ? 
                            LinearGradient(
                                colors: [achievement.category.color.opacity(0.3), achievement.category.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.theme.textTertiary.opacity(0.1), Color.theme.textTertiary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 32))
                        .foregroundColor(achievement.isUnlocked ? achievement.category.color : Color.theme.textTertiary)
                        .scaleEffect(animateUnlock ? 1.1 : 1.0)
                }
                
                // Title and description
                VStack(spacing: .spacing.sm) {
                    Text(achievement.title)
                        .titleMedium()
                        .foregroundColor(achievement.isUnlocked ? Color.theme.textPrimary : Color.theme.textTertiary)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .bodyMedium()
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Unlock date or lock status
                if achievement.isUnlocked {
                    VStack(spacing: .spacing.xs) {
                        Text("Unlocked")
                            .labelMedium()
                            .foregroundColor(Color.theme.success)
                            .fontWeight(.medium)
                        
                        Text(formatFullUnlockDate(achievement.unlockedAt))
                            .font(.caption)
                            .foregroundColor(Color.theme.textTertiary)
                    }
                } else {
                    HStack(spacing: .spacing.xs) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        
                        Text("Not yet unlocked")
                            .labelMedium()
                    }
                    .foregroundColor(Color.theme.textTertiary)
                }
            }
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadiusLarge)
                .fill(
                    achievement.isUnlocked ? 
                    Color.theme.surface :
                    Color.theme.backgroundSecondary
                )
                .overlay(
                    RoundedRectangle(cornerRadius: .spacing.cornerRadiusLarge)
                        .strokeBorder(
                            achievement.isUnlocked ? 
                            LinearGradient(
                                colors: [achievement.category.color.opacity(0.5), achievement.category.color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: achievement.isUnlocked ? achievement.category.color.opacity(0.1) : Color.black.opacity(0.05),
                    radius: achievement.isUnlocked ? 15 : 8,
                    x: 0,
                    y: achievement.isUnlocked ? 5 : 2
                )
        )
        .scaleEffect(animateUnlock ? 1.02 : 1.0)
        .onAppear {
            if achievement.isUnlocked {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                    animateUnlock = true
                }
            }
        }
    }
    
    private func formatUnlockDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFullUnlockDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AchievementCategoryFilterView: View {
    @Binding var selectedCategory: Achievement.AchievementCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing.sm) {
                // All categories button
                CategoryFilterButton(
                    title: "All",
                    color: Color.theme.primary,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // Individual category buttons
                ForEach(Achievement.AchievementCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.rawValue,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, .spacing.containerPadding)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .labelMedium()
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, .spacing.md)
                .padding(.vertical, .spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.15))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Achievement Category Extension
extension Achievement.AchievementCategory {
    var color: Color {
        switch self {
        case .goals:
            return Color.theme.primary
        case .progress:
            return Color.theme.secondary
        case .streaks:
            return Color.theme.warning
        case .analysis:
            return Color.theme.accent
        case .social:
            return Color(hex: "6C5CE7")
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: .spacing.lg) {
            // Unlocked achievement
            AchievementCard(
                achievement: Achievement(
                    id: "first_goal",
                    title: "Goal Setter",
                    description: "Set your first nutrition goals and start your healthy journey",
                    icon: "target",
                    category: .goals,
                    unlockedAt: Date(),
                    isUnlocked: true
                )
            )
            
            // Locked achievement
            AchievementCard(
                achievement: Achievement(
                    id: "week_streak",
                    title: "Week Warrior",
                    description: "Track your nutrition for 7 consecutive days",
                    icon: "flame.fill",
                    category: .streaks,
                    unlockedAt: Date(),
                    isUnlocked: false
                )
            )
            
            // Compact versions
            VStack(spacing: .spacing.sm) {
                AchievementCard(
                    achievement: Achievement(
                        id: "first_analysis",
                        title: "First Step",
                        description: "Complete your first food analysis",
                        icon: "camera.fill",
                        category: .progress,
                        unlockedAt: Date(),
                        isUnlocked: true
                    ),
                    isCompact: true
                )
                
                AchievementCard(
                    achievement: Achievement(
                        id: "social_share",
                        title: "Share the Love",
                        description: "Share your progress with friends",
                        icon: "heart.fill",
                        category: .social,
                        unlockedAt: Date(),
                        isUnlocked: false
                    ),
                    isCompact: true
                )
            }
            
            // Category filter
            AchievementCategoryFilterView(selectedCategory: .constant(.goals))
        }
        .containerPadding()
    }
}