import SwiftUI

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .slide.combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        AnyTransition.scale(scale: 0.8)
            .combined(with: .opacity)
    }
    
    static var bottomSlide: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static var topSlide: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    static var cardFlip: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity
                .animation(.easeInOut(duration: 0.25))
                .combined(with: .modifier(
                    active: RotationModifier(angle: -90),
                    identity: RotationModifier(angle: 0)
                )),
            removal: .opacity
                .animation(.easeInOut(duration: 0.25))
                .combined(with: .modifier(
                    active: RotationModifier(angle: 90),
                    identity: RotationModifier(angle: 0)
                ))
        )
    }
}

struct RotationModifier: ViewModifier {
    let angle: Double
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
    }
}

struct CircularRevealModifier: ViewModifier {
    let isShowing: Bool
    @State private var animationAmount: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .clipShape(
                Circle()
                    .scale(animationAmount)
            )
            .onAppear {
                if isShowing {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        animationAmount = 3
                    }
                }
            }
            .onChange(of: isShowing) { newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animationAmount = newValue ? 3 : 0
                }
            }
    }
}

struct BlurTransitionModifier: ViewModifier {
    let isShowing: Bool
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isShowing ? 0 : 10)
            .opacity(isShowing ? 1 : 0)
    }
}

extension View {
    func circularReveal(isShowing: Bool) -> some View {
        modifier(CircularRevealModifier(isShowing: isShowing))
    }
    
    func blurTransition(isShowing: Bool) -> some View {
        modifier(BlurTransitionModifier(isShowing: isShowing))
    }
}