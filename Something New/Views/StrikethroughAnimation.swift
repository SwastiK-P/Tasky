import SwiftUI

struct StrikethroughAnimation: ViewModifier {
    let isActive: Bool
    @State private var width: CGFloat = 0
    private let softHaptic = UIImpactFeedbackGenerator(style: .soft)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationHaptic = UINotificationFeedbackGenerator()
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    if isActive {
                        Rectangle()
                            .fill(Color.primary)
                            .frame(width: width, height: 1.5)
                            .offset(y: geo.size.height * 0.5)
                            .onAppear {
                                // Only prepare haptics if we're marking complete
                                if !isActive {
                                    return
                                }
                                
                                // Prepare haptics
                                softHaptic.prepare()
                                mediumHaptic.prepare()
                                heavyHaptic.prepare()
                                rigidHaptic.prepare()
                                notificationHaptic.prepare()
                                
                                // Play line drawing sound
                                SoundManager.playSound("Line")
                                
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    width = geo.size.width
                                }
                                
                                // More frequent haptic feedback
                                let intervals: [(TimeInterval, (UIImpactFeedbackGenerator, CGFloat))] = [
                                    (0.0, (softHaptic, 0.3)),
                                    (0.05, (softHaptic, 0.4)),
                                    (0.1, (softHaptic, 0.4)),
                                    (0.15, (mediumHaptic, 0.5)),
                                    (0.2, (mediumHaptic, 0.5)),
                                    (0.25, (mediumHaptic, 0.6)),
                                    (0.3, (rigidHaptic, 0.6)),
                                    (0.35, (rigidHaptic, 0.7)),
                                    (0.4, (heavyHaptic, 0.7)),
                                    (0.45, (heavyHaptic, 0.8)),
                                    (0.5, (heavyHaptic, 0.9)),
                                    (0.55, (heavyHaptic, 1.0))
                                ]
                                
                                for (delay, (generator, intensity)) in intervals {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                        generator.impactOccurred(intensity: intensity)
                                    }
                                }
                                
                                // Final tick feedback
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    rigidHaptic.impactOccurred(intensity: 1.0)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        notificationHaptic.notificationOccurred(.success)
                                    }
                                }
                            }
                    } else {
                        Color.clear
                            .onAppear {
                                width = 0
                            }
                    }
                }
            }
    }
}

extension View {
    func animatedStrikethrough(isActive: Bool) -> some View {
        modifier(StrikethroughAnimation(isActive: isActive))
    }
} 
