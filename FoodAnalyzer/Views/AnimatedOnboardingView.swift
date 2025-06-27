import SwiftUI

struct AnimatedOnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var animateElements = false
    @Namespace private var namespace
    
    let pages = [
        OnboardingPage(
            title: "Snap Your Food",
            subtitle: "Take a photo of any meal to instantly analyze its nutritional content",
            imageName: "camera.fill",
            gradientColors: [Color.blue, Color.purple]
        ),
        OnboardingPage(
            title: "Get AI Insights",
            subtitle: "Our AI provides detailed nutrition breakdown and personalized health tips",
            imageName: "sparkles",
            gradientColors: [Color.purple, Color.pink]
        ),
        OnboardingPage(
            title: "Track Your Goals",
            subtitle: "Set nutrition goals and monitor your progress over time",
            imageName: "chart.line.uptrend.xyaxis",
            gradientColors: [Color.orange, Color.red]
        ),
        OnboardingPage(
            title: "Live Healthier",
            subtitle: "Make informed food choices and improve your eating habits",
            imageName: "heart.fill",
            gradientColors: [Color.green, Color.mint]
        )
    ]
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            isCurrentPage: currentPage == index,
                            namespace: namespace
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                bottomSection
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animateElements = true
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: pages[currentPage].gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: currentPage)
    }
    
    private var bottomSection: some View {
        VStack(spacing: 20) {
            PageIndicator(numberOfPages: pages.count, currentPage: currentPage)
            
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button(action: {
                        withAnimation(.spring()) {
                            currentPage -= 1
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .transition(.scale)
                }
                
                Button(action: handleNextAction) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundColor(pages[currentPage].gradientColors[0])
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .bounce(trigger: currentPage == pages.count - 1)
            }
            .padding(.horizontal, 30)
        }
        .padding(.bottom, 40)
        .opacity(animateElements ? 1 : 0)
        .offset(y: animateElements ? 0 : 50)
    }
    
    private func handleNextAction() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring()) {
                currentPage += 1
            }
            HapticManager.shared.impact(.light)
        } else {
            withAnimation(.spring()) {
                isPresented = false
            }
            HapticManager.shared.notification(.success)
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isCurrentPage: Bool
    let namespace: Namespace.ID
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                    .scaleEffect(animateIcon ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(isCurrentPage ? 1 : 0.8)
                    .rotationEffect(.degrees(isCurrentPage ? 0 : -10))
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isCurrentPage)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isCurrentPage ? 1 : 0.5)
                    .scaleEffect(isCurrentPage ? 1 : 0.9)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(isCurrentPage ? 1 : 0.5)
                    .offset(y: isCurrentPage ? 0 : 20)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isCurrentPage)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateIcon = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let gradientColors: [Color]
}

struct PageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(currentPage == index ? 1 : 0.4))
                    .frame(width: currentPage == index ? 30 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
            }
        }
    }
}

struct ParallaxOnboardingView: View {
    @Binding var isPresented: Bool
    @GestureState private var dragOffset: CGSize = .zero
    @State private var currentIndex = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<4) { index in
                    OnboardingCard(
                        index: index,
                        currentIndex: currentIndex,
                        dragOffset: dragOffset,
                        geometry: geometry
                    )
                }
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let threshold = geometry.size.width * 0.3
                        
                        if value.translation.width < -threshold && currentIndex < 3 {
                            withAnimation(.spring()) {
                                currentIndex += 1
                            }
                        } else if value.translation.width > threshold && currentIndex > 0 {
                            withAnimation(.spring()) {
                                currentIndex -= 1
                            }
                        }
                    }
            )
        }
    }
}

struct OnboardingCard: View {
    let index: Int
    let currentIndex: Int
    let dragOffset: CGSize
    let geometry: GeometryProxy
    
    var offset: CGFloat {
        let cardOffset = CGFloat(index - currentIndex) * geometry.size.width
        return cardOffset + dragOffset.width
    }
    
    var scale: CGFloat {
        let distance = abs(CGFloat(index - currentIndex))
        return 1 - (distance * 0.1)
    }
    
    var opacity: Double {
        let distance = abs(CGFloat(index - currentIndex))
        return distance < 2 ? 1 - (distance * 0.3) : 0
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hue: Double(index) * 0.2, saturation: 0.8, brightness: 0.9),
                        Color(hue: Double(index) * 0.2 + 0.1, saturation: 0.7, brightness: 0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.7)
            .overlay(
                VStack(spacing: 30) {
                    Image(systemName: ["camera.fill", "sparkles", "chart.line.uptrend.xyaxis", "heart.fill"][index])
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text(["Snap Your Food", "Get AI Insights", "Track Your Goals", "Live Healthier"][index])
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            )
            .offset(x: offset)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(Double(offset) * 0.02))
    }
}

#Preview {
    AnimatedOnboardingView(isPresented: .constant(true))
}