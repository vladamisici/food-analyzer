import SwiftUI

struct AnimatedLoadingView: View {
    @State private var rotation = 0.0
    @State private var scale: CGFloat = 1.0
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.theme.primary.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .scaleEffect(scale)
                        .offset(y: -20)
                        .rotationEffect(.degrees(rotation + Double(index * 120)))
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.2),
                            value: rotation
                        )
                }
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.theme.primary)
                    .scaleEffect(scale)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: scale
                    )
            }
            .frame(width: 100, height: 100)
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.theme.textSecondary)
                .multilineTextAlignment(.center)
                .fadeIn(delay: 0.3)
        }
        .padding()
        .onAppear {
            rotation = 360
            scale = 1.2
        }
    }
}

struct PulsingDotsView: View {
    @State private var opacity = [0.4, 0.4, 0.4]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.theme.primary)
                    .frame(width: 8, height: 8)
                    .opacity(opacity[index])
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: opacity[index]
                    )
            }
        }
        .onAppear {
            for index in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                    opacity[index] = 1.0
                }
            }
        }
    }
}

struct ProgressRingView: View {
    let progress: Double
    let lineWidth: CGFloat = 8
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.theme.primary.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.theme.primary, Color.theme.accent]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animatedProgress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.theme.textPrimary)
                .scaleIn()
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            animatedProgress = newValue
        }
    }
}

struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray.opacity(0.1)
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.3)
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        AnimatedLoadingView(message: "Analyzing your food...")
        
        PulsingDotsView()
        
        ProgressRingView(progress: 0.75)
            .frame(width: 100, height: 100)
        
        ShimmerView()
            .frame(height: 50)
            .padding(.horizontal)
    }
    .padding()
}