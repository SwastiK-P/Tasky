import Foundation
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        if UserDefaults.standard.bool(forKey: "enableHaptics") {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserDefaults.standard.bool(forKey: "enableHaptics") else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
} 