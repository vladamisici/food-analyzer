import SwiftUI

struct SlideInModifier: ViewModifier {
    let delay: Double
    @State private var isShowing = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: isShowing ? 0 : -100)
            .opacity(isShowing ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    isShowing = true
                }
            }
    }
}

struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var isShowing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isShowing ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4).delay(delay)) {
                    isShowing = true
                }
            }
    }
}

struct ScaleInModifier: ViewModifier {
    let delay: Double
    @State private var isShowing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isShowing ? 1 : 0.8)
            .opacity(isShowing ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)) {
                    isShowing = true
                }
            }
    }
}

struct BounceModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    scale = 1.2
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                    scale = 1.0
                }
            }
    }
}

struct ShakeModifier: ViewModifier {
    @State private var shake = false
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? -5 : 0)
            .onChange(of: trigger) { _ in
                withAnimation(Animation.easeInOut(duration: 0.05).repeatCount(5, autoreverses: true)) {
                    shake.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    shake = false
                }
            }
    }
}

struct PulsatingModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                if isActive {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        scale = 1.1
                    }
                }
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        scale = 1.1
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scale = 1.0
                    }
                }
            }
    }
}

struct ParallaxModifier: ViewModifier {
    let magnitude: CGFloat
    @State private var offset: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                withAnimation(.spring()) {
                    offset = .zero
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let translation = value.translation
                        offset = CGSize(
                            width: translation.width * magnitude,
                            height: translation.height * magnitude
                        )
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                    }
            )
    }
}

extension View {
    func slideIn(delay: Double = 0) -> some View {
        modifier(SlideInModifier(delay: delay))
    }
    
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
    
    func scaleIn(delay: Double = 0) -> some View {
        modifier(ScaleInModifier(delay: delay))
    }
    
    func bounce(trigger: Bool) -> some View {
        modifier(BounceModifier(trigger: trigger))
    }
    
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
    
    func pulsating(isActive: Bool) -> some View {
        modifier(PulsatingModifier(isActive: isActive))
    }
    
    func parallax(magnitude: CGFloat = 0.1) -> some View {
        modifier(ParallaxModifier(magnitude: magnitude))
    }
}