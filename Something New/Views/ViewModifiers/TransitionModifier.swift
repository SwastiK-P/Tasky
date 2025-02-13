import SwiftUI

struct TransitionModifier: ViewModifier {
    let frame: CGRect
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(0.1)
            .offset(
                x: frame.midX - UIScreen.main.bounds.width/2,
                y: frame.midY - UIScreen.main.bounds.height/2
            )
    }
}

extension View {
    func thumbnailTransition(from frame: CGRect) -> some View {
        modifier(TransitionModifier(frame: frame))
    }
} 