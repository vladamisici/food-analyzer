import SwiftUI

struct SuccessAnimationView: View {
    @State private var isAnimating = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var circleScale: CGFloat = 0
    @State private var circleOpacity: Double = 0
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onComplete()
                }
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(Color.theme.primary.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .scaleEffect(circleScale)
                        .opacity(circleOpacity)
                    
                    Circle()
                        .fill(Color.theme.primary.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(circleScale * 0.9)
                        .opacity(circleOpacity)
                    
                    Circle()
                        .fill(Color.theme.primary)
                        .frame(width: 90, height: 90)
                        .scaleEffect(circleScale * 0.8)
                        .opacity(circleOpacity)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 45, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(checkmarkScale)
                                .rotationEffect(.degrees(checkmarkScale * 360))
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Analysis Complete!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.theme.textPrimary)
                        .scaleIn(delay: 0.5)
                    
                    Text("Your food has been analyzed")
                        .font(.system(size: 16))
                        .foregroundColor(.theme.textSecondary)
                        .fadeIn(delay: 0.7)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.theme.surface)
                    .shadow(radius: 20)
            )
            .scaleEffect(isAnimating ? 1 : 0.8)
            .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            animateSuccess()
        }
    }
    
    private func animateSuccess() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isAnimating = true
            circleOpacity = 1
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
            circleScale = 1
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
            checkmarkScale = 1
        }
        
        HapticManager.shared.notification(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            onComplete()
        }
    }
}

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: i,
                color: [Color.red, Color.blue, Color.green, Color.yellow, Color.purple, Color.orange].randomElement()!,
                x: CGFloat.random(in: -200...200),
                y: -300,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.3...1.0)
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 10, height: 20)
            .scaleEffect(piece.scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: piece.x, y: piece.y + yOffset)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: false)
                ) {
                    yOffset = 800
                    rotation = piece.rotation + 360
                }
            }
    }
}

struct ErrorAnimationView: View {
    let message: String
    let onDismiss: () -> Void
    @State private var isShaking = false
    @State private var scale: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(isShaking ? -5 : 5))
                
                VStack(spacing: 8) {
                    Text("Oops!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.theme.textPrimary)
                    
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: onDismiss) {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.theme.primary)
                        .cornerRadius(25)
                }
                .scaleIn(delay: 0.5)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.theme.surface)
                    .shadow(radius: 20)
            )
            .shake(trigger: isShaking)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1
            }
            
            withAnimation(
                Animation.easeInOut(duration: 0.1)
                    .repeatCount(5, autoreverses: true)
            ) {
                isShaking.toggle()
            }
            
            HapticManager.shared.notification(.error)
        }
    }
}

#Preview {
    ZStack {
        Color.theme.background
        
        VStack(spacing: 40) {
            SuccessAnimationView {
                print("Success completed")
            }
            
            ErrorAnimationView(message: "Failed to analyze image") {
                print("Error dismissed")
            }
        }
    }
}