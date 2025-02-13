import SwiftUI

struct AnimatedIconContainer: View {
    let content: AnyView
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var isPressed = false
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                feedbackManager.playHaptic(style: .soft)
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3)) {
                        isPressed = false
                    }
                }
            }
    }
} 