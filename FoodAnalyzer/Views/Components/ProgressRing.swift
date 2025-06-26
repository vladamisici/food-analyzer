import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let gradient: LinearGradient
    let backgroundColor: Color
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 100,
        gradient: LinearGradient = LinearGradient(
            colors: [Color.theme.primary, Color.theme.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        backgroundColor: Color = Color.theme.textTertiary.opacity(0.2)
    ) {
        self.progress = min(max(progress, 0), 1) // Clamp between 0 and 1
        self.lineWidth = lineWidth
        self.size = size
        self.gradient = gradient
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animatedProgress)
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newProgress
            }
        }
    }
}

struct ProgressRingWithLabel: View {
    let title: String
    let progress: Double
    let current: String
    let target: String
    let color: Color
    let size: CGFloat
    
    init(
        title: String,
        progress: Double,
        current: String,
        target: String,
        color: Color = Color.theme.primary,
        size: CGFloat = 100
    ) {
        self.title = title
        self.progress = progress
        self.current = current
        self.target = target
        self.color = color
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: .spacing.sm) {
            ZStack {
                ProgressRing(
                    progress: progress,
                    lineWidth: size * 0.08,
                    size: size,
                    gradient: LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                VStack(spacing: .spacing.xs) {
                    Text(current)
                        .font(.system(size: size * 0.16, weight: .bold, design: .rounded))
                        .foregroundColor(Color.theme.textPrimary)
                    
                    Text("of \(target)")
                        .font(.system(size: size * 0.1, weight: .medium))
                        .foregroundColor(Color.theme.textSecondary)
                }
            }
            
            Text(title)
                .font(.system(size: size * 0.12, weight: .medium))
                .foregroundColor(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    VStack(spacing: .spacing.lg) {
        ProgressRing(progress: 0.75)
        
        ProgressRingWithLabel(
            title: "Calories",
            progress: 0.65,
            current: "1,300",
            target: "2,000",
            color: Color.theme.primary
        )
        
        HStack(spacing: .spacing.lg) {
            ProgressRingWithLabel(
                title: "Protein",
                progress: 0.8,
                current: "120g",
                target: "150g",
                color: Color.theme.secondary,
                size: 80
            )
            
            ProgressRingWithLabel(
                title: "Carbs",
                progress: 0.45,
                current: "112g",
                target: "250g",
                color: Color.theme.warning,
                size: 80
            )
            
            ProgressRingWithLabel(
                title: "Fat",
                progress: 0.92,
                current: "62g",
                target: "67g",
                color: Color.theme.accent,
                size: 80
            )
        }
    }
    .containerPadding()
}